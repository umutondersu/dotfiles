function add-desktop --description "Install desktop-specific devbox packages"
    # Parse arguments
    argparse n/dry-run l/list -- $argv
    or return

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
    if set -q _flag_dry_run
        bash ~/dotfiles/setup/install-desktop-packages.sh --dry-run
    else
        bash ~/dotfiles/setup/install-desktop-packages.sh
    end
end
