function tses --description 'Create or attach to a tmux session in a specified directory'
    # Set the local variable `dir` to the first argument passed to the function.
    set -l dir $argv[1]

    # If no directory provided, use current directory
    if test -z "$dir"
        set dir (pwd)
    end

    # Check if the directory specified by `dir` does not exist.
    # If it doesn't, create the directory (and any necessary parent directories).
    if not test -d "$dir"
        mkdir -p "$dir"
    end

    # Resolve the directory path to handle relative paths and symlinks
    set -l current_dir (realpath "$dir")
    set -l repo_root ""
    set -l session_name ""

    # Walk up the directory tree to find a git repository
    set -l check_dir $current_dir
    while test "$check_dir" != "/"
        if test -d "$check_dir/.git"
            set repo_root $check_dir
            break
        end
        set check_dir (dirname "$check_dir")
    end

    # If we found a repo root, create hierarchical session name
    if test -n "$repo_root"
        # Get the repo name
        set -l repo_name (basename "$repo_root")
        # Get the relative path from repo root to target directory
        set -l rel_path (string replace "$repo_root/" "" "$current_dir/")
        set rel_path (string replace -r '/$' '' $rel_path)

        # If we're at the repo root, just use repo name
        if test "$current_dir" = "$repo_root"
            set session_name $repo_name
        else
            # Create hierarchical name: repo-subdir1-subdir2
            set session_name (string replace "/" "-" "$repo_name/$rel_path")
        end
    else
        # Not in a repo, use basename as before
        set session_name (basename "$current_dir")
    end

    # Ensure the session name is tmux-safe (replace problematic characters)
    set session_name (string replace -r '[^a-zA-Z0-9_-]' '-' $session_name)

    # Check if a tmux session with the name `session_name` already exists.
    # If it does, either attach to it or switch to it depending on whether
    # the function is being run inside an existing tmux session.
    # If it does not exist, create a new tmux session with the name `session_name`
    # and set the starting directory to `dir`.
    if tmux has-session -t "$session_name" 2>/dev/null
        if test -n "$TMUX"
            tmux switch-client -t "$session_name"
        else
            tmux attach-session -t "$session_name"
        end
    else
        if test -n "$TMUX"
            tmux new-session -ds "$session_name" -c "$current_dir"
            tmux switch-client -t "$session_name"
        else
            tmux new-session -s "$session_name" -c "$current_dir"
        end
    end
end
