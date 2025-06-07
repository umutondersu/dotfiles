function update_git_root --description "Update GITROOT to point to the closest git root folder"
    # Try to find the git root directory
    set -l git_dir (command git rev-parse --show-toplevel 2>/dev/null)

    if test $status -eq 0
        # Git root found, set GITROOT
        set -gx GITROOT $git_dir
    else
        # Not in a git repository, unset GITROOT
        set -e GITROOT
    end
end

# Initial setup
update_git_root

# Update GITROOT whenever directory changes
function __update_git_root_on_pwd --on-variable PWD
    update_git_root
end
