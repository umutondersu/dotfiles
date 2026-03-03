# This function synchronizes devbox configurations bidirectionally:
# - Default: working → template (excludes desktop packages)
# - --from-template: template → working
function sync-devbox -d "Sync devbox configs bidirectionally"
    argparse from-template f/force n/dry-run -- $argv
    or return

    set -l working_config ~/.local/share/devbox/global/default/devbox.json
    set -l template_config ~/dotfiles/devbox.json
    set -l desktop_script ~/dotfiles/setup/install-desktop-packages.sh
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

        if not set -q _flag_force
            read -P "Apply changes to global devbox.json? [y/N] " -l confirm
            if not string match -qi y $confirm
                echo "Aborted."
                return 1
            end
        end

        mkdir -p (dirname $working_config)
        if not cp $template_config $working_config
            echo "Error: Failed to copy template to working config"
            return 1
        end

        echo "✓ Copied template to working config"
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

    if not set -q _flag_force
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
