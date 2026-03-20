function desktop-pkg --description "Manage desktop-specific devbox packages"
    # Parse arguments
    argparse n/dry-run l/list a/append r/remove i/install -- $argv
    or return

    # Remove package name(s) from the package file and uninstall
    if set -q _flag_remove
        set packages_file ~/dotfiles/desktop-packages.txt
        if not test -f $packages_file
            echo "Error: Package list not found at $packages_file"
            return 1
        end
        if test (count $argv) -eq 0
            echo "Error: No package name(s) provided to remove"
            return 1
        end
        for pkg in $argv
            if not grep -qx "$pkg" $packages_file
                echo "Error: '$pkg' not found in $packages_file"
                return 1
            end
            devbox global rm $pkg
            or begin
                echo "Error: 'devbox global remove $pkg' failed"
                return 1
            end
            grep -vx "$pkg" $packages_file > /tmp/desktop-packages-tmp.txt
            mv /tmp/desktop-packages-tmp.txt $packages_file
            echo "Removed '$pkg' from $packages_file"
        end
        return 0
    end

    # Append package name(s) to the package file
    if set -q _flag_append
        set packages_file ~/dotfiles/desktop-packages.txt
        if not test -f $packages_file
            echo "Error: Package list not found at $packages_file"
            return 1
        end
        if test (count $argv) -eq 0
            echo "Error: No package name(s) provided to append"
            return 1
        end
        for pkg in $argv
            set search_output (devbox search $pkg 2>&1)
            if not printf "%s\n" $search_output | grep -q "^\* $pkg "
                echo "Error: '$pkg' not found in devbox. Run 'devbox search $pkg' to check."
                return 1
            end
            echo "Installing '$pkg'..."
            if not devbox global add $pkg
                echo "Error: 'devbox global add $pkg' failed"
                return 1
            end
            echo $pkg >> $packages_file
            echo "Appended '$pkg' to $packages_file"
        end
        return 0
    end

    # List packages and exit
    if set -q _flag_list
        set packages_file ~/dotfiles/desktop-packages.txt
        if not test -f $packages_file
            echo "Error: Package list not found at $packages_file"
            return 1
        end
        echo "Desktop packages ($packages_file):"
        grep -v '^\s*#' $packages_file | grep -v '^\s*$'
        return 0
    end

    # Pass dry-run flag to the bash script if present
    if set -q _flag_install
        if set -q _flag_dry_run
            bash ~/dotfiles/setup/desktop/packages.sh --dry-run
        else
            bash ~/dotfiles/setup/desktop/packages.sh
        end
        return 0
    end

    # Default: print usage
    echo "Usage: desktop-pkg [flags] [package...]"
    echo ""
    echo "Flags:"
    echo "  -i, --install       Install all packages from desktop-packages.txt"
    echo "  -a, --append <pkg>  Validate, install, and append package(s) to desktop-packages.txt"
    echo "  -r, --remove <pkg>  Uninstall and remove package(s) from desktop-packages.txt"
    echo "  -l, --list          List packages in desktop-packages.txt"
    echo "  -n, --dry-run       Dry run (use with -i)"
end
