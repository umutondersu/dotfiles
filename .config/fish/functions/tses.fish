function tses --description 'Create or attach to a tmux session in a specified directory'
    # Set the local variable `dir` to the first argument passed to the function.
    set -l dir $argv[1]
    
    # Check if the directory specified by `dir` does not exist.
    # If it doesn't, create the directory (and any necessary parent directories).
    if not test -d $dir
        mkdir -p $dir
    end
    
    # Set the local variable `session_name` to the base name of the directory path stored in `dir`.
    set -l session_name (basename $dir)
    
    # Check if a tmux session with the name `session_name` already exists.
    # If it does, either attach to it or switch to it depending on whether
    # the function is being run inside an existing tmux session.
    # If it does not exist, create a new tmux session with the name `session_name`
    # and set the starting directory to `dir`.
    if tmux has-session -t $session_name 2>/dev/null
        if test -n "$TMUX"
            tmux switch-client -t $session_name
        else
            tmux attach-session -t $session_name
        end
    else
        if test -n "$TMUX"
            tmux new-session -ds $session_name -c $dir
            tmux switch-client -t $session_name
        else
            tmux new-session -s $session_name -c $dir
        end
    end
end
