# This function synchronizes devbox configurations bidirectionally:
# - Default: working → template (excludes desktop packages)
# - --from-template: template → working (includes desktop packages via add-desktop)
function sync-devbox -d "Sync devbox configs bidirectionally"
    argparse from-template f/force n/dry-run -- $argv
    or return

    set -l working_config ~/.local/share/devbox/global/default/devbox.json
    set -l template_config ~/dotfiles/devbox.json
    set -l desktop_script ~/dotfiles/setup/install-desktop-packages.sh
    set -l desktop_packages_file ~/dotfiles/desktop-packages.txt

    # Sync FROM template TO working (re-copy from template + add desktop)
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

        # Add desktop packages
        echo "Adding desktop packages..."
        if set -q _flag_dry_run
            if not add-desktop --dry-run
                echo "Error: Dry run of add-desktop failed"
                return 1
            end
        else
            if not add-desktop
                echo "Error: Failed to add desktop packages"
                # Rollback to backup
                if test -n "$backup_config"
                    echo "Rolling back to previous config..."
                    cp $backup_config $working_config
                    rm $backup_config
                    echo "✓ Restored previous config"
                end
                return 1
            end
        end

        # Validate desktop packages were added
        if not set -q _flag_dry_run
            echo ""
            echo "Validating desktop packages..."
            set -l desktop_packages (grep -v '^[[:space:]]*#' $desktop_packages_file | grep -v '^[[:space:]]*$' | awk -F'@' '{print $1}')
            set -l missing_packages

            for pkg in $desktop_packages
                if not command -v $pkg &>/dev/null
                    set -a missing_packages $pkg
                end
            end

            if test (count $missing_packages) -gt 0
                echo "Warning: Some desktop packages were not found in PATH:"
                for pkg in $missing_packages
                    echo "  - $pkg"
                end
                echo ""
                echo "Note: They may have been installed but require a shell restart."
            else
                echo "✓ All desktop packages validated successfully"
            end
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

    # Extract desktop packages from packages file
    set -l desktop_packages (grep -v '^[[:space:]]*#' $desktop_packages_file | grep -v '^[[:space:]]*$' | xargs)

    if test (count $desktop_packages) -eq 0
        echo "Warning: No desktop packages found in $desktop_packages_file"
        return 1
    end

    # Extract packages from working config, excluding desktop packages
    set -l temp_file (mktemp)
    jq '.packages' $working_config >$temp_file

    # Remove desktop packages from extracted list
    for pkg in $desktop_packages
        set -l pkg_name (string split '@' $pkg)[1]
        set -l temp_file2 (mktemp)
        jq --arg name "$pkg_name" 'map(select(startswith($name + "@") | not))' $temp_file >$temp_file2
        mv $temp_file2 $temp_file
    end

    # Update only the packages array in template, keeping everything else
    if set -q _flag_dry_run
        echo "[DRY RUN] Would update template config at:"
        echo "  $template_config"
        echo ""
        echo "[DRY RUN] Packages that would be synced:"
        jq -r '.[]' $temp_file
        echo ""
        echo "[DRY RUN] Desktop packages that would be excluded:"
        echo "  $desktop_packages"
        rm $temp_file
    else
        set -l final_temp (mktemp)
        jq --slurpfile pkgs $temp_file '.packages = $pkgs[0]' $template_config >$final_temp
        mv $final_temp $template_config
        rm $temp_file

        echo "✓ Synced devbox config to template (excluded desktop packages)"
        echo "  Template: $template_config"
        echo ""
        echo "Desktop packages excluded: $desktop_packages"
    end
end
