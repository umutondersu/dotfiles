# This function synchronizes devbox configurations bidirectionally:
# - Default: working → template (excludes desktop packages)
# - --from-template: template → working
function sync-devbox -d "Sync devbox configs bidirectionally"
    argparse H/help R/from-template f/force A/all n/dry-run p/platform= -- $argv
    or return

    if set -q _flag_help
        echo "Usage: sync-devbox [OPTIONS]"
        echo ""
        echo "Synchronize devbox configurations between working and template."
        echo ""
        echo "Options:"
        echo "  -H, --help             Show this help message"
        echo "  -A, --all              Apply all changes without per-package selection"
        echo "  -f, --force            Skip all confirmations"
        echo "  -n, --dry-run          Show what would change without applying"
        echo "  -p, --platform <name>  Template platform: linux or macos (default: auto-detect)"
        echo "  -R, --from-template    Sync template -> working (default: working -> template)"
        return 0
    end

    set -l working_config ~/.local/share/devbox/global/default/devbox.json

    # Detect platform unless overridden with --platform
    set -l platform linux
    if set -q _flag_platform
        set platform $_flag_platform
    else if test "$(uname -s)" = Darwin
        set platform macos
    end
    switch $platform
        case linux macos
        case '*'
            echo "Error: Invalid platform '$platform' (expected linux or macos)"
            return 1
    end

    set -l template_config ~/dotfiles/devbox.$platform.json
    set -l desktop_script ~/dotfiles/setup/desktop/packages.sh
    set -l desktop_packages_file ~/dotfiles/desktop-packages.txt

    # Validate shared prerequisites
    if not test -f $desktop_script
        echo "Error: Desktop packages script not found at $desktop_script"
        return 1
    end

    if not test -f $desktop_packages_file
        echo "Error: Desktop packages file not found at $desktop_packages_file"
        return 1
    end

    set -l desktop_packages (grep -v '^[[:space:]]*#' $desktop_packages_file | grep -v '^[[:space:]]*$')

    if test (count $desktop_packages) -eq 0
        echo "Warning: No desktop packages found in $desktop_packages_file"
        return 1
    end

    # Helper: extract packages from a config file, excluding desktop packages
    # Usage: set result (_filtered_pkgs <config_file>)
    function _filtered_pkgs --no-scope-shadowing
        set -l config $argv[1]
        set -l tmp (mktemp)
        jq '.packages' $config >$tmp
        for pkg in $desktop_packages
            set -l tmp2 (mktemp)
            if string match -qr '^[a-z]+:' $pkg
                # Nix flake (e.g. github:org/repo): exact match
                jq --arg name "$pkg" 'map(select(. != $name))' $tmp >$tmp2
            else
                # Standard devbox package (e.g. neovim or neovim@latest): match by name prefix
                set -l pkg_name (string split '@' $pkg)[1]
                jq --arg name "$pkg_name" 'map(select(startswith($name + "@") | not))' $tmp >$tmp2
            end
            mv $tmp2 $tmp
        end
        jq -r '.[]' $tmp
        rm $tmp
    end

    # Helper: compute and display diff, prompt, then apply
    # Usage: _sync_diff_and_apply <current_pkgs_list> <new_pkgs_list> <dest_config> <apply_command>
    function _show_diff --no-scope-shadowing
        # Called as: _show_diff $current_pkgs -- $new_pkgs
        set -l sep_idx (contains -i -- -- $argv)
        set -l current_pkgs $argv[1..(math $sep_idx - 1)]
        set -l new_pkgs $argv[(math $sep_idx + 1)..-1]

        set -l added_pkgs
        set -l removed_pkgs

        for pkg in $new_pkgs
            if not contains -- $pkg $current_pkgs
                set -a added_pkgs $pkg
            end
        end

        for pkg in $current_pkgs
            if not contains -- $pkg $new_pkgs
                set -a removed_pkgs $pkg
            end
        end

        if test (count $added_pkgs) -gt 0
            echo "Packages to add:"
            for pkg in $added_pkgs
                echo "  + $pkg"
            end
            echo ""
        end

        if test (count $removed_pkgs) -gt 0
            echo "Packages to remove:"
            for pkg in $removed_pkgs
                echo "  - $pkg"
            end
            echo ""
        end

        # Return 1 (no changes) or 0 (changes exist) via exit status
        if test (count $added_pkgs) -eq 0 -a (count $removed_pkgs) -eq 0
            return 1
        end
        return 0
    end

    # Helper: interactive per-package selection via fzf (or fallback prompts)
    # Outputs filtered new_pkgs on stdout, returns 0 on confirm / 1 on abort
    # All user-facing output goes to stderr so stdout is clean for capture
    function _interactive_select
        set -l sep_idx (contains -i -- -- $argv)
        set -l current_pkgs $argv[1..(math $sep_idx - 1)]
        set -l new_pkgs $argv[(math $sep_idx + 1)..-1]

        set -l added_pkgs
        set -l removed_pkgs
        for pkg in $new_pkgs
            if not contains -- $pkg $current_pkgs
                set -a added_pkgs $pkg
            end
        end
        for pkg in $current_pkgs
            if not contains -- $pkg $new_pkgs
                set -a removed_pkgs $pkg
            end
        end

        set -l selected_added
        set -l selected_removed

        if type -q fzf
            if set -q added_pkgs[1]
                echo "" >&2
                echo "=== Select packages to ADD ===" >&2
                set selected_added (
                    printf '%s\n' $added_pkgs \
                    | fzf --multi \
                          --prompt="TAB=⬇ toggle / ENTER=confirm > " \
                          --bind 'start:select-all' \
                          --height=40% --reverse
                )
            end
            if set -q removed_pkgs[1]
                echo "" >&2
                echo "=== Select packages to REMOVE ===" >&2
                set selected_removed (
                    printf '%s\n' $removed_pkgs \
                    | fzf --multi \
                          --prompt="TAB=⬇ toggle / ENTER=confirm > " \
                          --bind 'start:select-all' \
                          --height=40% --reverse
                )
            end
        else
            for pkg in $added_pkgs
                read -P "Add '$pkg'? [y/N] " -l confirm
                if string match -qi y $confirm
                    set -a selected_added $pkg
                end
            end
            for pkg in $removed_pkgs
                read -P "Remove '$pkg'? [y/N] " -l confirm
                if string match -qi y $confirm
                    set -a selected_removed $pkg
                end
            end
        end

        # Build final list: start from current, add selections, remove selections
        set -l final_pkgs $current_pkgs
        for pkg in $selected_added
            if not contains -- $pkg $final_pkgs
                set -a final_pkgs $pkg
            end
        end
        for pkg in $selected_removed
            set final_pkgs (string match -v -- $pkg $final_pkgs)
        end

        echo "" >&2
        echo "Summary:" >&2
        if set -q selected_added[1]
            echo "  + "(string join ', ' $selected_added) >&2
        end
        if set -q selected_removed[1]
            echo "  - "(string join ', ' $selected_removed) >&2
        end
        if not set -q selected_added[1]; and not set -q selected_removed[1]
            echo "  No changes selected." >&2
            return 1
        end

        printf '%s\n' $final_pkgs
        return 0
    end

    # Sync FROM template TO working
    if set -q _flag_from_template
        if not test -f $template_config
            echo "Error: Template devbox.json not found at $template_config"
            return 1
        end

        set -l current_pkgs
        if test -f $working_config
            set current_pkgs (_filtered_pkgs $working_config)
        end
        set -l new_pkgs (_filtered_pkgs $template_config)

        if not _show_diff $current_pkgs -- $new_pkgs
            echo "✓ Working config already up to date, no changes needed"
            return 0
        end

        if set -q _flag_dry_run
            echo "[DRY RUN] No changes made."
            return 0
        end

        if not set -q _flag_all; and not set -q _flag_force
            set new_pkgs (_interactive_select $current_pkgs -- $new_pkgs)
            or return 1
        else if not set -q _flag_force
            read -P "Apply changes to global devbox.json? [y/N] " -l confirm
            if not string match -qi y $confirm
                echo "Aborted."
                return 1
            end
        end

        mkdir -p (dirname $working_config)

        # Desktop packages = all working packages minus the filtered (non-desktop) set
        # current_pkgs already holds the filtered working packages (computed above)
        set -l working_desktop_pkgs
        if test -f $working_config
            set -l all_working_pkgs (jq -r '.packages[]' $working_config 2>/dev/null)
            for pkg in $all_working_pkgs
                if not contains -- $pkg $current_pkgs
                    set -a working_desktop_pkgs $pkg
                end
            end
        end

        # Merged list: template non-desktop packages + preserved working desktop packages
        set -l temp_new (mktemp)
        set -l temp_desktop (mktemp)
        printf '%s\n' $new_pkgs | jq -Rs '[split("\n")[] | select(length > 0)]' >$temp_new
        printf '%s\n' $working_desktop_pkgs | jq -Rs '[split("\n")[] | select(length > 0)]' >$temp_desktop

        set -l temp_merged (mktemp)
        jq -s '.[0] + .[1]' $temp_new $temp_desktop >$temp_merged
        rm $temp_new $temp_desktop

        set -l base_config $template_config
        if test -f $working_config
            set base_config $working_config
        end

        set -l final_temp (mktemp)
        if not jq --slurpfile pkgs $temp_merged '.packages = $pkgs[0]' $base_config >$final_temp
            echo "Error: Failed to build merged working config"
            rm $temp_merged $final_temp
            return 1
        end
        rm $temp_merged
        mv $final_temp $working_config

        echo "✓ Synced template to working config (preserved desktop packages)"
        return 0
    end

    # Default: Sync FROM working TO template
    if not test -f $working_config
        echo "Error: Working devbox.json not found at $working_config"
        return 1
    end

    if not test -f $template_config
        echo "Error: Template devbox.json not found at $template_config"
        return 1
    end

    # Build the merged package list: preserve template order, append new packages
    set -l working_filtered (_filtered_pkgs $working_config)
    set -l temp_filtered (mktemp)
    printf '%s\n' $working_filtered | jq -Rs '[split("\n")[] | select(length > 0)]' >$temp_filtered

    set -l temp_t (mktemp)
    set -l temp_result (mktemp)
    jq '.packages' $template_config >$temp_t
    jq -s '
        .[0] as $template_pkgs |
        .[1] as $working_pkgs |
        ($template_pkgs | map(select(. as $p | $working_pkgs | index($p) != null))) +
        ($working_pkgs | map(select(. as $p | $template_pkgs | index($p) == null)))
    ' $temp_t $temp_filtered >$temp_result
    rm $temp_t $temp_filtered

    set -l current_pkgs (jq -r '.packages[]' $template_config 2>/dev/null)
    set -l new_pkgs (jq -r '.[]' $temp_result)

    if not _show_diff $current_pkgs -- $new_pkgs
        echo "✓ Template already up to date, no changes needed"
        rm $temp_result
        return 0
    end

    if set -q _flag_dry_run
        echo "[DRY RUN] No changes made."
        rm $temp_result
        return 0
    end

    if not set -q _flag_all; and not set -q _flag_force
        set new_pkgs (_interactive_select $current_pkgs -- $new_pkgs)
        or begin
            rm $temp_result
            return 1
        end
        printf '%s\n' $new_pkgs | jq -Rs '[split("\n")[] | select(length > 0)]' >$temp_result
    else if not set -q _flag_force
        read -P "Apply changes to template devbox.json? [y/N] " -l confirm
        if not string match -qi y $confirm
            echo "Aborted."
            rm $temp_result
            return 1
        end
    end

    set -l final_temp (mktemp)
    jq --slurpfile pkgs $temp_result '.packages = $pkgs[0]' $template_config >$final_temp
    mv $final_temp $template_config
    rm $temp_result

    echo "✓ Synced devbox config to template (excluded desktop packages)"
end
