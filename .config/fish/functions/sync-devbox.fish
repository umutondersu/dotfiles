function sync-devbox -d "Sync devbox working config to git template (excluding desktop packages)"
    set -l working_config ~/.local/share/devbox/global/default/devbox.json
    set -l template_config ~/dotfiles/.devbox/devbox.json
    set -l desktop_script ~/dotfiles/setup/install-desktop-packages.sh

    if not test -f $working_config
        echo "Error: Working devbox.json not found at $working_config"
        return 1
    end

    if not test -f $desktop_script
        echo "Error: Desktop packages script not found at $desktop_script"
        return 1
    end

    # Extract desktop packages from install script
    # Parses "devbox global add pkg1 pkg2 pkg3" line
    set -l desktop_packages (grep -oP 'devbox global add \K.*' $desktop_script | string split ' ')

    if test (count $desktop_packages) -eq 0
        echo "Warning: No desktop packages found in $desktop_script"
        return 1
    end

    # Extract packages from working config, excluding desktop packages
    set -l temp_file (mktemp)
    jq '.packages' $working_config > $temp_file
    
    # Remove desktop packages from extracted list
    for pkg in $desktop_packages
        set -l pkg_name (string split '@' $pkg)[1]
        set -l temp_file2 (mktemp)
        jq --arg name "$pkg_name" 'map(select(startswith($name + "@") | not))' $temp_file > $temp_file2
        mv $temp_file2 $temp_file
    end
    
    # Update only the packages array in template, keeping everything else
    set -l final_temp (mktemp)
    jq --slurpfile pkgs $temp_file '.packages = $pkgs[0]' $template_config > $final_temp
    mv $final_temp $template_config
    rm $temp_file

    echo "✓ Synced devbox config to template (excluded desktop packages)"
    echo "  Template: $template_config"
    echo ""
    echo "Desktop packages excluded: $desktop_packages"
end
