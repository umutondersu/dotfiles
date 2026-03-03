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

    # Sync FROM template TO working (re-copy from template)
    if set -q _flag_from_template
        if not test -f $template_config
            echo "Error: Template devbox.json not found at $template_config"
            return 1
        end

        if not test -f $desktop_script
            echo "Error: Desktop packages script not found at $desktop_script"
            return 1
        end

        if not test -f $desktop_packages_file
            echo "Error: Desktop packages file not found at $desktop_packages_file"
            return 1
        end

        # Confirmation prompt (unless --force is used)
        if not set -q _flag_force
            if test -f $working_config
                if set -q _flag_dry_run
                    echo "[DRY RUN] Would overwrite working config at:"
                    echo "  $working_config"
                else
                    echo "Warning: This will overwrite your working config at:"
                    echo "  $working_config"
                    echo ""
                    read -P "Continue? [y/N] " -l confirm
                    if not string match -qi y $confirm
                        echo "Aborted."
                        return 1
                    end
                end
            end
        end

        # Create directory if it doesn't exist
        set -l working_dir (dirname $working_config)
        mkdir -p $working_dir

        # Backup current working config for potential rollback
        set -l backup_config ""
        if test -f $working_config
            set backup_config (mktemp)
            cp $working_config $backup_config
        end

        # Copy template to working
        if set -q _flag_dry_run
            echo "[DRY RUN] Would copy template to working config:"
            echo "  From: $template_config"
            echo "  To:   $working_config"
            echo ""
        else
            if not cp $template_config $working_config
                echo "Error: Failed to copy template to working config"
                if test -n "$backup_config"
                    rm $backup_config
                end
                return 1
            end

            echo "✓ Copied template to working config"
            echo "  From: $template_config"
            echo "  To:   $working_config"
            echo ""
        end

        # Clean up backup
        if test -n "$backup_config"
            rm $backup_config
        end

        return 0
    end

    # Default behavior: Sync FROM working TO template (existing functionality)
    if not test -f $working_config
        echo "Error: Working devbox.json not found at $working_config"
        return 1
    end

    if not test -f $desktop_script
        echo "Error: Desktop packages script not found at $desktop_script"
        return 1
    end

    if not test -f $desktop_packages_file
        echo "Error: Desktop packages file not found at $desktop_packages_file"
        return 1
    end

    # Extract desktop packages from packages file (one entry per list element)
    set -l desktop_packages (grep -v '^[[:space:]]*#' $desktop_packages_file | grep -v '^[[:space:]]*$')

    if test (count $desktop_packages) -eq 0
        echo "Warning: No desktop packages found in $desktop_packages_file"
        return 1
    end

    # Extract packages from working config, excluding desktop packages
    set -l temp_filtered (mktemp)
    jq '.packages' $working_config >$temp_filtered
    for pkg in $desktop_packages
        set -l pkg_name (string split '@' $pkg)[1]
        set -l temp2 (mktemp)
        jq --arg name "$pkg_name" 'map(select(startswith($name + "@") | not))' $temp_filtered >$temp2
        mv $temp2 $temp_filtered
    end

    # Compare sorted sets — if identical, nothing to do
    set -l temp_template_pkgs (mktemp)
    set -l temp_filtered_sorted (mktemp)
    jq '.packages | sort' $template_config >$temp_template_pkgs
    jq sort $temp_filtered >$temp_filtered_sorted

    if diff -q $temp_template_pkgs $temp_filtered_sorted >/dev/null 2>&1
        echo "✓ Template already up to date, no changes needed"
        rm $temp_filtered $temp_template_pkgs $temp_filtered_sorted
        return 0
    end

    rm $temp_template_pkgs $temp_filtered_sorted

    # Sets differ: build the new package list preserving template order.
    # Keep template packages that still exist in filtered working set,
    # then append any new packages (present in filtered working but not in template).
    set -l temp_t (mktemp)
    set -l temp_result (mktemp)
    jq '.packages' $template_config >$temp_t
    jq -s '
        .[0] as $template_pkgs |
        .[1] as $working_pkgs |
        ($template_pkgs | map(select(. as $p | $working_pkgs | index($p) != null))) +
        ($working_pkgs | map(select(. as $p | $template_pkgs | index($p) == null)))
    ' $temp_t $temp_filtered >$temp_result
    rm $temp_t

    # Compute the diff between current template and new state
    set -l current_pkgs (jq -r '.packages[]' $template_config 2>/dev/null)
    set -l new_pkgs (jq -r '.[]' $temp_result)

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

    # Show the diff
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

    # Dry-run: stop here
    if set -q _flag_dry_run
        echo "[DRY RUN] No changes made."
        rm $temp_filtered $temp_result
        return 0
    end

    # Confirm before applying (unless --force)
    if not set -q _flag_force
        read -P "Apply changes? [y/N] " -l confirm
        if not string match -qi y $confirm
            echo "Aborted."
            rm $temp_filtered $temp_result
            return 1
        end
    end

    # Apply: update only the packages array in template, keeping everything else
    set -l final_temp (mktemp)
    jq --slurpfile pkgs $temp_result '.packages = $pkgs[0]' $template_config >$final_temp
    mv $final_temp $template_config
    rm $temp_filtered $temp_result

    echo "✓ Synced devbox config to template (excluded desktop packages)"
end
