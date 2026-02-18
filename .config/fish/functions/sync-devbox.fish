# This function synchronizes devbox configurations bidirectionally:
# - Default: working → template (excludes desktop packages)
# - --from-template: template → working (includes desktop packages via add-desktop)
function sync-devbox -d "Sync devbox configs bidirectionally"
    argparse from-template f/force -- $argv
    or return

    set -l working_config ~/.local/share/devbox/global/default/devbox.json
    set -l template_config ~/dotfiles/devbox.json
    set -l desktop_script ~/dotfiles/setup/install-desktop-packages.sh

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

        # Confirmation prompt (unless --force is used)
        if not set -q _flag_force
            if test -f $working_config
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

        # Add desktop packages
        echo "Adding desktop packages..."
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

        # Validate desktop packages were added
        echo ""
        echo "Validating desktop packages..."
        set -l desktop_packages (grep -oP '^\s+"\K[^"]+(?="@)' $desktop_script)
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

    # Extract desktop packages from install script
    set -l desktop_packages (grep -oP '^\s+"\K[^"]+(?="\s*$)' $desktop_script)

    if test (count $desktop_packages) -eq 0
        echo "Warning: No desktop packages found in $desktop_script"
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
    set -l final_temp (mktemp)
    jq --slurpfile pkgs $temp_file '.packages = $pkgs[0]' $template_config >$final_temp
    mv $final_temp $template_config
    rm $temp_file

    echo "✓ Synced devbox config to template (excluded desktop packages)"
    echo "  Template: $template_config"
    echo ""
    echo "Desktop packages excluded: $desktop_packages"
end
