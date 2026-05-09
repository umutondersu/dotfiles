function nixfind --description "Find a Nix package version and output a nix shell command"
    # Check hard dependencies (always required)
    for dep in curl stat date
        if not command -q $dep
            echo "Error: nixfind requires '$dep' but it was not found in PATH" >&2
            return 1
        end
    end

    # Split argv on '--': everything after it is the command to run inside nix shell
    set cmd_args
    set pre_args
    set found_sep 0
    for a in $argv
        if test $found_sep -eq 1
            set -a cmd_args $a
        else if test "$a" = --
            set found_sep 1
        else
            set -a pre_args $a
        end
    end

    argparse 'c/channel=' 'l/list' 'p/pick' 's/shell' 'r/run' 'f/flake' 'h/help' -- $pre_args 2>/dev/null
    or begin
        echo "Usage: nixfind [options] <pkg[@version]>..." >&2
        return 1
    end

    # Valid combos: --pick --run and --pick --shell. Everything else is mutually exclusive.
    set _action_count 0
    set -q _flag_list;  and set _action_count (math $_action_count + 1)
    set -q _flag_pick;  and set _action_count (math $_action_count + 1)
    set -q _flag_run;   and set _action_count (math $_action_count + 1)
    set -q _flag_flake; and set _action_count (math $_action_count + 1)
    set -q _flag_shell; and set _action_count (math $_action_count + 1)

    if test $_action_count -gt 1
        set _ok 0
        if set -q _flag_pick; and test $_action_count -eq 2
            set -q _flag_run;   and set _ok 1
            set -q _flag_shell; and set _ok 1
        end
        if test $_ok -eq 0
            echo "Error: conflicting flags — only --pick --run and --pick --shell may be combined" >&2
            return 1
        end
    end

    if set -q _flag_help; or test (count $argv) -lt 1
        echo "Usage: nixfind [options] <pkg[@version]>..."
        echo ""
        echo "  Multiple packages:  nixfind go@1.22 ripgrep jq@1"
        echo ""
        echo "Options:"
        echo "  -c, --channel <channel>  Nixpkgs channel (default: nixpkgs-unstable)"
        echo "  -l, --list               List all matching versions for a single package"
        echo "  -s, --shell              Launch nix shell with the package(s)"
        echo "      --shell -- <cmd>     Launch nix shell and run a command"
        echo "  -r, --run                Run the package's default binary with nix run (single package only)"
        echo "  -f, --flake              Output a flake.nix with all packages pinned as a devShell"
        echo "  -p, --pick               Interactively pick a version with fzf (single package only)"
        echo "      --pick --shell       Pick a version and launch nix shell"
        echo "      --pick --run         Pick a version and run with nix run"
        echo "  -h, --help               Show this help"
        return 0
    end

    set channel nixpkgs-unstable
    if set -q _flag_channel
        set channel $_flag_channel
    end

    # Check optional dependencies based on flags
    if set -q _flag_pick
        if not command -q fzf
            echo "Error: --pick requires 'fzf' but it was not found in PATH" >&2
            return 1
        end
    end
    if set -q _flag_shell; or set -q _flag_run
        if not command -q nix
            echo "Error: --shell/--run requires 'nix' but it was not found in PATH" >&2
            return 1
        end
    end

    # --list and --pick only make sense for a single package
    if set -q _flag_list; or set -q _flag_pick
        if test (count $argv) -ne 1
            echo "Error: --list and --pick only work with a single package" >&2
            return 1
        end
    end

    # Resolve all pkg@version tokens into flakes
    set flakes
    set key_names
    set revisions
    set rev_orders

    for token in $argv
        set parts (string split @ $token)
        set pkg $parts[1]
        set ver ""
        set raw_ver ""
        if test (count $parts) -gt 1
            set raw_ver $parts[2]
            set ver $raw_ver
        end

        # Validate: empty package name
        if test -z "$pkg"
            echo "Error: invalid package token '$token' (empty package name)" >&2
            return 1
        end

        # Treat @latest as no version pin
        if test "$ver" = latest
            set ver ""
        end

        # Warn: trailing @ with no version (but not @latest which is valid)
        if test (count $parts) -gt 1; and test -z "$raw_ver"
            echo "Warning: '$token' has a trailing '@' with no version — using latest" >&2
        end

        # --list: delegate and return immediately
        if set -q _flag_list
            _nixfind_list $pkg $ver $channel
            return $status
        end

        # --pick: delegate and return immediately
        if set -q _flag_pick
            set result (_nixfind_pick $pkg $ver $channel)
            if test $status -ne 0; or test -z "$result"
                return 1
            end
            if set -q _flag_run
                _nixfind_exec_flakeref run $result
            else if set -q _flag_shell
                _nixfind_exec_flakeref shell $result $cmd_args
            else
                echo $result
            end
            return $status
        end

        set resolved (_nixfind_resolve $pkg $ver $channel)
        if test $status -ne 0
            return 1
        end
        set rev (string match -r 'revision=([a-f0-9]*)' $resolved[1])[2]
        set key (string match -r 'keyName=([^&]+)' $resolved[1])[2]
        set order $resolved[2]

        # Deduplicate: skip if key+rev already collected
        set dup 0
        for i in (seq (count $key_names))
            if test "$key_names[$i]" = "$key"; and test "$revisions[$i]" = "$rev"
                set dup 1
                break
            end
        end
        if test $dup -eq 1
            continue
        end

        if test -n "$rev"
            set -a flakes "github:NixOS/nixpkgs/$rev#$key"
        else
            set -a flakes "nixpkgs#$key"
        end
        set -a key_names $key
        set -a revisions $rev
        set -a rev_orders $order
    end

    # --flake: generate a flake.nix devShell
    if set -q _flag_flake
        set n (count $key_names)
        _nixfind_gen_flake $n $key_names $revisions $rev_orders
        return 0
    end

    # --run: only valid for a single package
    if set -q _flag_run
        if test (count $flakes) -ne 1
            echo "Error: --run only works with a single package" >&2
            return 1
        end
        nix run $flakes[1]
        return 0
    end

    # --shell: launch nix shell with all resolved flakes
    if set -q _flag_shell
        if test (count $cmd_args) -gt 0
            nix shell $flakes --command $cmd_args
        else
            nix shell $flakes
        end
        return 0
    end

    # Default: print flakes
    for f in $flakes
        echo $f
    end
end

# Fetch and filter Lazamar entries for a package.
# Returns list of matched entry strings (oldest to newest).
function _nixfind_fetch_entries
    set pkg $argv[1]
    set ver $argv[2]
    set channel $argv[3]

    # Nix attr names are always URL-safe (letters, digits, hyphen, underscore, dot)
    set cache_file "/tmp/nixfind-$pkg-$channel.html"

    if test -f $cache_file; and test (math (date +%s) - (stat -c %Y $cache_file)) -lt 3600
        set html (cat $cache_file)
    else
        set html (curl -sf --max-time 15 "https://lazamar.co.uk/nix-versions/?package=$pkg&channel=$channel" 2>/dev/null)
        if test $status -ne 0
            echo "Error: failed to fetch results for '$pkg'" >&2
            return 1
        end
        printf '%s' $html > $cache_file
    end

    if not string match -q '*lazamar*' $html
        echo "Error: unexpected response for '$pkg'" >&2
        return 1
    end

    set entries (string match -ar \
        'version=[^&]+&amp;fullName=[^&]+&amp;keyName=[^&]+&amp;revision=[a-f0-9]+' \
        $html)

    if test (count $entries) -eq 0
        echo "No results found for '$pkg' on channel '$channel'" >&2
        return 1
    end

    # Filter to entries whose keyName matches the package exactly
    set pkg_re (string escape --style=regex $pkg)
    set filtered
    for e in $entries
        if string match -qr "keyName=$pkg_re([_&]|\$)" $e
            set -a filtered $e
        end
    end
    if test (count $filtered) -gt 0
        set entries $filtered
    end

    # Filter by version prefix if provided
    if test -n "$ver"
        set ver_re (string escape --style=regex $ver)
        set matched
        for e in $entries
            if string match -qr "version=$ver_re(\\.\\d|&amp;|\$)" $e
                set -a matched $e
            end
        end
        if test (count $matched) -eq 0
            echo "No matching version found for '$pkg $ver' on channel '$channel'" >&2
            echo "Try: nixfind $pkg" >&2
            return 1
        end
        set entries $matched
    end

    printf '%s\n' $entries
end

# Resolve latest version via nix eval.
# Returns two lines: pseudo-entry string + order (999999 = newest possible)
function _nixfind_resolve_latest
    set pkg $argv[1]

    if not command -q nix
        echo "Error: resolving latest requires 'nix' but it was not found in PATH" >&2
        return 1
    end

    set ver (nix eval "nixpkgs#$pkg.version" --raw 2>/dev/null)
    if test $status -ne 0; or test -z "$ver"
        if string match -qr '^[a-zA-Z][a-zA-Z0-9]*_\d' $pkg
            set base (string replace -r '_\d.*$' '' $pkg)
            set ver_hint (string replace -r '^[^_]+_' '' $pkg | string replace -a _ .)
            echo "Error: '$pkg' not found in current nixpkgs — versioned attrs like this are often removed over time." >&2
            echo "Try: nixfind $base@$ver_hint" >&2
        else
            echo "Error: '$pkg' not found in nixpkgs" >&2
        end
        return 1
    end

    echo "revision=&keyName=$pkg&version=$ver"
    echo 999999
end

# Resolve a single pkg@version.
# Returns two lines: entry string + order index
function _nixfind_resolve
    set pkg $argv[1]
    set ver $argv[2]
    set channel $argv[3]

    # No version specified: use nix eval for up-to-date latest
    if test -z "$ver"
        _nixfind_resolve_latest $pkg
        return $status
    end

    set entries (_nixfind_fetch_entries $pkg $ver $channel)
    if test $status -ne 0
        return 1
    end

    echo $entries[-1]
    echo (count $entries)
end

# List all versions for a single package
function _nixfind_list
    set pkg $argv[1]
    set ver $argv[2]
    set channel $argv[3]

    set entries (_nixfind_fetch_entries $pkg $ver $channel)
    if test $status -ne 0
        return 1
    end

    # Prepend "latest" row when not filtering by version
    if test -z "$ver"
        if command -q nix
            set latest_ver (nix eval "nixpkgs#$pkg.version" --raw 2>/dev/null)
            if test -n "$latest_ver"
                printf "%-12s  nixpkgs#%s  (latest)\n" $latest_ver $pkg
            end
        end
    end

    for e in $entries
        set v (string match -r 'version=([^&]+)' $e)[2]
        set k (string match -r 'keyName=([^&]+)' $e)[2]
        set r (string match -r 'revision=([a-f0-9]+)' $e)[2]
        printf "%-12s  github:NixOS/nixpkgs/%s#%s\n" $v $r $k
    end
end

# Pick a version interactively with fzf, return the flake string
function _nixfind_pick
    set pkg $argv[1]
    set ver $argv[2]
    set channel $argv[3]

    set entries (_nixfind_fetch_entries $pkg $ver $channel)
    if test $status -ne 0
        return 1
    end

    set versions
    # Prepend latest option using nix eval (if nix is available)
    if command -q nix
        set latest_ver (nix eval "nixpkgs#$pkg.version" --raw 2>/dev/null)
        if test -n "$latest_ver"
            set -a versions "latest ($latest_ver)"
        end
    end
    for e in $entries
        set -a versions (string match -r 'version=([^&]+)' $e)[2]
    end

    set chosen (printf '%s\n' $versions | fzf --no-sort --prompt="$pkg> ")
    if test -z "$chosen"
        return 1
    end

    if string match -q 'latest *' $chosen
        echo "nixpkgs#$pkg"
        return 0
    end

    for e in $entries
        set v (string match -r 'version=([^&]+)' $e)[2]
        if test "$v" = "$chosen"
            set k (string match -r 'keyName=([^&]+)' $e)[2]
            set r (string match -r 'revision=([a-f0-9]+)' $e)[2]
            echo "github:NixOS/nixpkgs/$r#$k"
            return 0
        end
    end
end

# Execute a single flake ref with nix run or nix shell.
# Usage: _nixfind_exec_flakeref <run|shell> <flakeref> [cmd...]
function _nixfind_exec_flakeref
    set mode $argv[1]
    set flakeref $argv[2]
    set cmd $argv[3..]

    if test "$mode" = run
        nix run $flakeref
    else
        if test (count $cmd) -gt 0
            nix shell $flakeref --command $cmd
        else
            nix shell $flakeref
        end
    end
end

# Generate a flake.nix devShell with all packages pinned.
# Uses single base nixpkgs (newest rev) + overlay for older-rev packages.
# Args: <n> <key1..n> <rev1..n> <order1..n>
function _nixfind_gen_flake
    set n $argv[1]
    set i2 (math $n + 1)
    set i3 (math $n + 2)
    set i4 (math $n \* 2 + 1)
    set i5 (math $n \* 2 + 2)
    set i6 (math $n \* 3 + 1)
    set key_names $argv[2..$i2]
    set revisions $argv[$i3..$i4]
    set orders    $argv[$i5..$i6]

    # Find the base revision: the one with the highest order value (newest)
    set base_rev ""
    set base_order -1
    for i in (seq $n)
        if test $orders[$i] -gt $base_order
            set base_order $orders[$i]
            set base_rev $revisions[$i]
        end
    end

    # Collect unique non-base revisions that need overlay inputs
    set overlay_revs
    set overlay_inputs
    for i in (seq $n)
        set rev $revisions[$i]
        if test "$rev" = "$base_rev"
            continue
        end
        set found 0
        for r in $overlay_revs
            if test "$r" = "$rev"
                set found 1
                break
            end
        end
        if test $found -eq 0
            set -a overlay_revs $rev
            set -a overlay_inputs "nixpkgs-"(string sub -l 8 $rev)
        end
    end

    # Base URL: empty rev means latest HEAD
    if test -z "$base_rev"
        set base_url "github:NixOS/nixpkgs"
    else
        set base_url "github:NixOS/nixpkgs/$base_rev"
    end

    # Pre-compute which packages need overlay (non-base rev)
    set overlay_keys
    set overlay_input_for_key
    for i in (seq $n)
        if test "$revisions[$i]" != "$base_rev"
            set -a overlay_keys $key_names[$i]
            for j in (seq (count $overlay_revs))
                if test "$overlay_revs[$j]" = "$revisions[$i]"
                    set -a overlay_input_for_key $overlay_inputs[$j]
                    break
                end
            end
        end
    end

    echo "{"
    echo "  description = \"Dev shell generated by nixfind\";"
    echo ""
    echo "  inputs = {"
    echo "    nixpkgs.url = \"$base_url\";"
    for j in (seq (count $overlay_revs))
        echo "    $overlay_inputs[$j].url = \"github:NixOS/nixpkgs/$overlay_revs[$j]\";"
    end
    echo "  };"
    echo ""
    echo -n "  outputs = { self, nixpkgs"
    for inp in $overlay_inputs
        echo -n ", $inp"
    end
    echo ", ... }:"
    echo "    let"
    echo "      system = \"x86_64-linux\";"
    if test (count $overlay_keys) -gt 0
        echo "      pkgs = nixpkgs.legacyPackages.\${system}"
        echo "        .extend (final: prev: {"
        for i in (seq (count $overlay_keys))
            set inp $overlay_input_for_key[$i]
            set k $overlay_keys[$i]
            echo "          $k = $inp.legacyPackages.\${system}.$k;"
        end
        echo "        });"
    else
        echo "      pkgs = nixpkgs.legacyPackages.\${system};"
    end
    echo "    in {"
    echo "      devShells.\${system}.default = pkgs.mkShell {"
    echo "        packages = ["
    for i in (seq $n)
        echo "          pkgs.$key_names[$i]"
    end
    echo "        ];"
    echo "      };"
    echo "    };"
    echo "}"
end
