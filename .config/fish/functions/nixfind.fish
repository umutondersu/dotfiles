function nixfind --description "Find a Nix package version and output a nix shell command"
    # Check hard dependencies (always required)
    for dep in curl python3 stat date
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
    set pkg_names
    set key_names
    set revisions

    for token in $argv
        set parts (string split @ $token)
        set pkg $parts[1]
        set ver ""
        if test (count $parts) -gt 1
            set ver $parts[2]
        end

        # Validate: empty package name
        if test -z "$pkg"
            echo "Error: invalid package token '$token' (empty package name)" >&2
            return 1
        end

        # Warn: trailing @ with no version
        if test (count $parts) -gt 1; and test -z "$ver"
            echo "Warning: '$token' has a trailing '@' with no version — using latest" >&2
        end

        # --list: delegate to existing list logic for single package
        if set -q _flag_list
            _nixfind_list $pkg $ver $channel
            return $status
        end

        # --pick: delegate to existing pick logic for single package
        if set -q _flag_pick
            set result (_nixfind_pick $pkg $ver $channel)
            if test $status -ne 0; or test -z "$result"
                return 1
            end
            set r (string replace 'github:NixOS/nixpkgs/' '' (string split '#' $result)[1])
            set k (string split '#' $result)[2]
            if set -q _flag_run
                _nixfind_exec $r $k run
            else if set -q _flag_shell
                _nixfind_exec $r $k shell $cmd_args
            else
                echo $result
            end
            return 0
        end

        set resolved (_nixfind_resolve $pkg $ver $channel)
        if test $status -ne 0
            return 1
        end
        set rev (string match -r 'revision=([a-f0-9]*)' $resolved)[2]
        set key (string match -r 'keyName=([^&]+)' $resolved)[2]
        if test -n "$rev"
            set -a flakes "github:NixOS/nixpkgs/$rev#$key"
        else
            set -a flakes "nixpkgs#$key"
        end
        set -a pkg_names $pkg
        set -a key_names $key
        set -a revisions $rev
    end

    # --flake: generate a flake.nix devShell
    if set -q _flag_flake
        set n (count $key_names)
        _nixfind_gen_flake $n $key_names $revisions
        return 0
    end

    # --run: only valid for a single package
    if set -q _flag_run
        if test (count $flakes) -ne 1
            echo "Error: --run only works with a single package" >&2
            return 1
        end
        _nixfind_exec $revisions[1] $key_names[1] run
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

# Resolve latest version via nix search, returns pseudo-entry: revision=&keyName=<attr>&version=<ver>
function _nixfind_resolve_latest
    set pkg $argv[1]

    if not command -q nix
        echo "Error: resolving latest requires 'nix' but it was not found in PATH" >&2
        return 1
    end

    set result (nix search nixpkgs $pkg --json 2>/dev/null | python3 -c "
import json, sys
pkg = sys.argv[1]
data = json.load(sys.stdin)
key = 'legacyPackages.x86_64-linux.' + pkg
if key in data:
    v = data[key]
    print('revision=&keyName=' + pkg + '&version=' + v['version'])
else:
    # fallback: find first entry whose attr equals pkg (handles arch differences)
    for k, v in data.items():
        attr = k.split('.')[-1]
        if attr == pkg:
            print('revision=&keyName=' + pkg + '&version=' + v['version'])
            sys.exit(0)
    print('')
" $pkg)

    if test -z "$result"
        echo "Error: '$pkg' not found in nixpkgs (via nix search)" >&2
        return 1
    end

    echo $result
end

# Resolve a single pkg@version to its best matching HTML entry string
function _nixfind_resolve
    set pkg $argv[1]
    set ver $argv[2]
    set channel $argv[3]

    # No version or @latest: use nix search for up-to-date latest
    if test -z "$ver"; or test "$ver" = latest
        _nixfind_resolve_latest $pkg
        return $status
    end

    set pkg_encoded (python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" $pkg)
    set url "https://lazamar.co.uk/nix-versions/?package=$pkg_encoded&channel=$channel"
    set cache_file "/tmp/nixfind-$pkg_encoded-$channel.html"

    if test -f $cache_file; and test (math (date +%s) - (stat -c %Y $cache_file)) -lt 3600
        set html (cat $cache_file)
    else
        set html (curl -sf --max-time 15 $url 2>/dev/null)
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

    set pkg_re (string escape --style=regex $pkg)
    set pat_key "keyName=$pkg_re([_&]|\$)"
    set filtered
    for e in $entries
        if string match -qr $pat_key $e
            set -a filtered $e
        end
    end
    if test (count $filtered) -gt 0
        set entries $filtered
    end

    set ver_re (string escape --style=regex $ver)
    set pat_ver "version=$ver_re(\\.\\d|&amp;|\$)"
    set matched
    for e in $entries
        if string match -qr $pat_ver $e
            set -a matched $e
        end
    end
    if test (count $matched) -eq 0
        echo "No matching version found for '$pkg $ver' on channel '$channel'" >&2
        echo "Try: nixfind $pkg" >&2
        return 1
    end

    echo $matched[-1]
end

# List all versions for a single package
function _nixfind_list
    set pkg $argv[1]
    set ver $argv[2]
    set channel $argv[3]

    set pkg_encoded (python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" $pkg)
    set cache_file "/tmp/nixfind-$pkg_encoded-$channel.html"

    if test -f $cache_file; and test (math (date +%s) - (stat -c %Y $cache_file)) -lt 3600
        set html (cat $cache_file)
    else
        set html (curl -sf --max-time 15 "https://lazamar.co.uk/nix-versions/?package=$pkg_encoded&channel=$channel" 2>/dev/null)
        if test $status -ne 0
            echo "Error: failed to fetch results for '$pkg'" >&2
            return 1
        end
        printf '%s' $html > $cache_file
    end

    set entries (string match -ar \
        'version=[^&]+&amp;fullName=[^&]+&amp;keyName=[^&]+&amp;revision=[a-f0-9]+' \
        $html)

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

    if test -n "$ver"
        set ver_re (string escape --style=regex $ver)
        set matched
        for e in $entries
            if string match -qr "version=$ver_re(\\.\\d|&amp;|\$)" $e
                set -a matched $e
            end
        end
        set entries $matched
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

    set pkg_encoded (python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" $pkg)
    set cache_file "/tmp/nixfind-$pkg_encoded-$channel.html"

    if test -f $cache_file; and test (math (date +%s) - (stat -c %Y $cache_file)) -lt 3600
        set html (cat $cache_file)
    else
        set html (curl -sf --max-time 15 "https://lazamar.co.uk/nix-versions/?package=$pkg_encoded&channel=$channel" 2>/dev/null)
        if test $status -ne 0
            echo "Error: failed to fetch results for '$pkg'" >&2
            return 1
        end
        printf '%s' $html > $cache_file
    end

    set entries (string match -ar \
        'version=[^&]+&amp;fullName=[^&]+&amp;keyName=[^&]+&amp;revision=[a-f0-9]+' \
        $html)

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

    if test -n "$ver"
        set ver_re (string escape --style=regex $ver)
        set matched
        for e in $entries
            if string match -qr "version=$ver_re(\\.\\d|&amp;|\$)" $e
                set -a matched $e
            end
        end
        set entries $matched
    end

    set versions
    for e in $entries
        set -a versions (string match -r 'version=([^&]+)' $e)[2]
    end

    set chosen (printf '%s\n' $versions | fzf --no-sort --prompt="$pkg> ")
    if test -z "$chosen"
        return 1
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

# Generate a flake.nix devShell with all packages pinned
# Args: <n> <key1..n> <rev1..n>
function _nixfind_gen_flake
    set n $argv[1]
    set i1 2
    set i2 (math $n + 1)
    set i3 (math $n + 2)
    set i4 (math $n \* 2 + 1)
    set key_names $argv[$i1..$i2]
    set revisions $argv[$i3..$i4]

    # Deduplicate: build a list of unique revisions and a short input name per unique rev.
    # Input name is nixpkgs-<first 8 chars of rev> to stay unique and readable.
    set uniq_revs
    set uniq_input_names
    set uniq_short_names
    set input_name_for   # parallel to key_names: which input each package uses
    set pkgs_name_for    # parallel to key_names: which pkgs-* binding each package uses

    for i in (seq $n)
        set rev $revisions[$i]
        # Empty rev = unpinned latest; use "nixpkgs" as the canonical input name
        if test -z "$rev"
            set short latest
            set input_name nixpkgs
        else
            set short (string sub -l 8 $rev)
            set input_name "nixpkgs-$short"
        end

        # Check if this rev is already in uniq_revs
        set found 0
        for j in (seq (count $uniq_revs))
            if test "$uniq_revs[$j]" = "$rev"
                set found 1
                break
            end
        end

        if test $found -eq 0
            set -a uniq_revs $rev
            set -a uniq_input_names $input_name
            set -a uniq_short_names $short
        end

        set -a input_name_for $input_name
        set -a pkgs_name_for $short
    end

    set u (count $uniq_revs)

    echo "{"
    echo "  description = \"Dev shell generated by nixfind\";"
    echo ""
    echo "  inputs = {"
    for j in (seq $u)
        if test -z "$uniq_revs[$j]"
            echo "    $uniq_input_names[$j].url = \"github:NixOS/nixpkgs\";"
        else
            echo "    $uniq_input_names[$j].url = \"github:NixOS/nixpkgs/$uniq_revs[$j]\";"
        end
    end
    echo "  };"
    echo ""
    echo -n "  outputs = { self"
    for j in (seq $u)
        echo -n ", $uniq_input_names[$j]"
    end
    echo ", ... }:"
    echo "    let"
    echo "      system = \"x86_64-linux\";"
    for j in (seq $u)
        set iname $uniq_input_names[$j]
        set short $uniq_short_names[$j]
        echo "      pkgs-$short = $iname.legacyPackages.\${system};"
    end
    echo "    in {"
    echo "      devShells.\${system}.default = pkgs-$pkgs_name_for[1].mkShell {"
    echo "        packages = ["
    for i in (seq $n)
        echo "          pkgs-$pkgs_name_for[$i].$key_names[$i]"
    end
    echo "        ];"
    echo "      };"
    echo "    };"
    echo "}"
end

# Helper: run nix shell/run
function _nixfind_exec
    set rev $argv[1]
    set attr $argv[2]
    set mode $argv[3]
    set cmd $argv[4..]
    set flake "github:NixOS/nixpkgs/$rev#$attr"
    if test "$mode" = run
        nix run $flake
    else if test (count $cmd) -gt 0
        nix shell $flake --command $cmd
    else
        nix shell $flake
    end
end
