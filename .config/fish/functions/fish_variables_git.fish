function fish_variables_git --description "Manage git tracking of fish_variables for intentional edits"
    set -l dotfiles_dir ~/dotfiles
    set -l fish_vars_path .config/fish/fish_variables
    
    # Check if we're in a git repo with fish_variables
    if not test -d $dotfiles_dir/.git
        echo "Error: $dotfiles_dir is not a git repository"
        return 1
    end
    
    if not test -f $dotfiles_dir/$fish_vars_path
        echo "Error: $dotfiles_dir/$fish_vars_path not found"
        return 1
    end
    
    # Parse command
    set -l cmd $argv[1]
    
    switch $cmd
        case unlock
            echo "🔓 Unlocking fish_variables for editing..."
            git -C $dotfiles_dir update-index --no-assume-unchanged $fish_vars_path
            echo "✅ You can now edit $fish_vars_path and commit changes"
            echo "💡 Run 'fish_variables_git lock' when done to re-enable ignore"
            
        case lock
            echo "🔒 Locking fish_variables (git will ignore local changes)..."
            git -C $dotfiles_dir update-index --assume-unchanged $fish_vars_path
            echo "✅ Local changes to $fish_vars_path will now be ignored"
            
        case status
            echo "📊 Checking fish_variables git tracking status..."
            set -l status_output (git -C $dotfiles_dir ls-files -v | grep fish_variables)
            
            if string match -q "h *" $status_output
                echo "🔒 Status: LOCKED (assume-unchanged is set)"
                echo "   Local changes are ignored by git"
                echo "   Run 'fish_variables_git unlock' to make changes"
            else if string match -q "H *" $status_output
                echo "🔓 Status: UNLOCKED (normal git tracking)"
                echo "   Changes will show in git status"
                echo "   Run 'fish_variables_git lock' after committing"
            else
                echo "⚠️  Status: UNKNOWN"
                echo "   File might not be tracked by git"
            end
            
        case help '*'
            echo "fish_variables_git - Manage git tracking of fish_variables"
            echo ""
            echo "Usage:"
            echo "  fish_variables_git unlock   Temporarily enable git tracking for editing"
            echo "  fish_variables_git lock     Re-enable git ignore (assume-unchanged)"
            echo "  fish_variables_git status   Check current tracking status"
            echo "  fish_variables_git help     Show this help message"
            echo ""
            echo "Workflow for making changes:"
            echo "  1. fish_variables_git unlock"
            echo "  2. Edit fish_variables or use 'set -U' commands"
            echo "  3. git add .config/fish/fish_variables && git commit"
            echo "  4. fish_variables_git lock"
    end
end
