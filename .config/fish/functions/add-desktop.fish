function add-desktop --description "Install desktop-specific devbox packages"
    # Parse arguments
    argparse n/dry-run -- $argv
    or return

    # Pass dry-run flag to the bash script if present
    if set -q _flag_dry_run
        bash ~/dotfiles/setup/install-desktop-packages.sh --dry-run
    else
        bash ~/dotfiles/setup/install-desktop-packages.sh
    end
end
