function gwt --description 'Git worktree manager'
    set -l cmd $argv[1]
    set -e argv[1]

    switch "$cmd"
        case add
            __gwt_add $argv
        case rm
            __gwt_rm $argv
        case ls
            __gwt_ls $argv
        case rename
            __gwt_rename $argv
        case pick
            __gwt_pick $argv
        case '' -h --help
            echo 'Usage: gwt <subcommand>'
            echo ''
            echo 'Subcommands:'
            echo '  add [<name>]                 Create worktree (no arg picks an origin branch)'
            echo '  rm [<branch>...] [-b] [-f]   Remove worktrees (args or fzf); -b deletes branch, -f forces'
            echo '  ls                           List worktrees'
            echo '  rename <old> <new>           Rename worktree directory and branch'
            echo '  pick [<branch>]              Pick a worktree and connect to its session'
            return 0
        case '*'
            echo "Unknown subcommand: $cmd" >&2
            gwt --help >&2
            return 1
    end
end

# Returns the absolute path of the main repo root, regardless of whether
# the current directory is the main repo or a linked worktree.
function __gwt_main_root
    set -l common (realpath (git rev-parse --git-common-dir))
    string replace -r '/\.git(/worktrees/.+)?$' '' "$common"
end

# Given a branch name, prints the worktree path that has it checked out.
# Prints nothing if not found.
function __gwt_branch_to_path
    git worktree list --porcelain | awk -v b="refs/heads/$argv[1]" '
        /^worktree / { cur = substr($0, 10) }
        $0 == "branch " b { print cur }
    '
end

# Connect to the tmux session for a worktree, creating it if needed.
function __gwt_connect
    set -l wt_path $argv[1]
    set -l branch $argv[2]
    set -l main_root (__gwt_main_root)
    set -l repo_name (basename "$main_root")

    set -l session_name (test "$wt_path" = "$main_root"; and echo "$repo_name"; or echo "$repo_name/$branch")
    if not tmux list-sessions -F '#{session_name}' 2>/dev/null | string match -q -- "$session_name"
        tmux new-session -d -s "$session_name" -c "$wt_path"
    end
    tmux switch-client -t "=$session_name"
end

function __gwt_add
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l main_root (__gwt_main_root)
    set -l name $argv[1]

    # No name given: fetch origin and pick a remote branch
    if test -z "$name"
        echo 'Fetching origin...'
        git fetch --prune origin >/dev/null 2>&1
        or begin
            echo 'Failed to fetch origin.' >&2
            return 1
        end

        or begin
            echo 'Failed to fetch origin.' >&2
            return 1
        end

        set -l remote_branches (git for-each-ref --format='%(refname:short)' --exclude='refs/remotes/origin/HEAD' 'refs/remotes/origin/')
        if test (count $remote_branches) -eq 0
            echo 'No remote branches found.' >&2
            return 1
        end

        set -l fzf_input
        for rb in $remote_branches
            set -a fzf_input (printf "%s\t%s" (string replace 'origin/' '' $rb) "$rb")
        end

        set -l chosen (printf "%s\n" $fzf_input | \
            fzf \
                --ansi \
                --no-sort \
                --prompt='Create worktree from branch> ' \
                --header='Enter to create worktree' \
                --delimiter='\t' \
                --with-nth='1' \
                --preview="PATH=$PATH /usr/bin/git log --oneline --decorate --graph --color=always -20 {2}" \
                --preview-window='right:66%:wrap' \
                --layout='reverse')

        if test -z "$chosen"
            return 0
        end

        set -l parts (string split \t "$chosen")
        set name $parts[1]
        set remote_ref $parts[2]
    end

    # Branch already has a worktree: connect to it like gwt pick
    set -l existing_wt (__gwt_branch_to_path "$name")
    if test -n "$existing_wt"
        __gwt_connect "$existing_wt" "$name"
        return 0
    end

    set -l wt_path (dirname "$main_root")/worktree/$name
    set -l wt_dir (dirname "$wt_path")

    if not test -d "$wt_dir"
        mkdir -p "$wt_dir"
        or begin
            echo "Failed to create directory: $wt_dir" >&2
            return 1
        end
    end

    if git show-ref --verify --quiet "refs/heads/$name"
        git worktree add "$wt_path" "$name" >/dev/null 2>&1
        or return 1
    else if set -q remote_ref
        git worktree add --track -b "$name" "$wt_path" "$remote_ref" >/dev/null 2>&1
        or return 1
    else
        git worktree add -b "$name" "$wt_path" >/dev/null 2>&1
        or return 1
    end

    __gwt_connect "$wt_path" "$name"
end

function __gwt_rm
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l delete_branch 0
    set -l force 0
    set -l names

    for arg in $argv
        switch "$arg"
            case -b --branch
                set delete_branch 1
            case -f --force
                set force 1
            case '*'
                set -a names $arg
        end
    end

    set -l main_path (git worktree list --porcelain | head -1 | string replace 'worktree ' '')

    set -l paths
    if test (count $names) -gt 0
        for name in $names
            if string match -q '/*' $name
                set -a paths $name
            else
                set -l match (__gwt_branch_to_path "$name")
                if test -z "$match"
                    echo "No worktree found for branch: $name" >&2
                    continue
                end
                set -a paths $match
            end
        end
    else
        # Build branch list (same format as pick)
        set -l branches
        set -l paths

        set -l main_path (git worktree list --porcelain | head -1 | string replace 'worktree ' '')

        for line in (git worktree list)
            set -l path (string split -m1 ' ' $line)[1]
            set -l rest (string replace -r '^\S+\s+' '' $line)
            set -l branch ''

            if string match -q '(bare)' -- $rest
                continue
            else if test "$path" = "$main_path"
                continue
            else if string match -qr '\[(.+)\]' $rest
                set branch (string match -r '\[(.+)\]' $rest)[2]
            else
                set branch '(detached HEAD)'
            end

            set -a branches "$branch"
            set -a paths "$path"
        end

        if test (count $branches) -eq 0
            echo 'No worktrees to remove.'
            return 0
        end

        set -l fzf_input
        for i in (seq 1 (count $branches))
            set -a fzf_input (printf "%s\t%s" "$branches[$i]" "$paths[$i]")
        end

        set -l chosen (printf "%s\n" $fzf_input | fzf \
            --multi \
            --ansi \
            --no-sort \
            --prompt='Remove worktrees> ' \
            --header='Tab to multi-select, Enter to confirm' \
            --delimiter='\t' \
            --with-nth='1' \
            --preview="PATH=$PATH /usr/bin/git -C {2} log --oneline --decorate --graph --color=always -20" \
            --preview-window='right:66%:wrap' \
            --layout='reverse')

        if test -z "$chosen"
            return 0
        end

        for line in $chosen
            set -l parts (string split \t "$line")
            set -a paths $parts[2]
        end
    end

    for path in $paths
        # Resolve branch name before removing the worktree
        set -l branch ''
        if test $delete_branch -eq 1
            set branch (git worktree list --porcelain | awk -v p="$path" '
                /^worktree / { cur = substr($0, 10) }
                cur == p && /^branch / { sub("refs/heads/", "", $2); print $2 }
            ')
        end

        set -l rm_args
        if test $force -eq 1
            set rm_args --force
        end

        git worktree remove $rm_args "$path"
        or continue

        echo "Removed: $path"

        # Find any tmux session whose start path matches the worktree path and kill it
        set -l session_name (tmux list-sessions -F '#{session_name} #{session_path}' 2>/dev/null | awk -v p="$path" '$2 == p {print $1; exit}')
        if test -n "$session_name"
            tmux kill-session -t "=$session_name"
            echo "Killed session: $session_name"
        end

        if test $delete_branch -eq 1 -a -n "$branch"
            if not git branch -d "$branch" 2>/dev/null
                read -l -P "Branch '$branch' is not fully merged. Force delete? [y/N] " confirm
                if string match -qi y "$confirm"
                    git branch -D "$branch"
                    and echo "Deleted branch: $branch"
                else
                    echo "Kept branch: $branch"
                end
            else
                echo "Deleted branch: $branch"
            end
        end
    end
end

function __gwt_rename
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l old_name $argv[1]
    set -l new_name $argv[2]

    if test -z "$old_name" -o -z "$new_name"
        echo 'Usage: gwt rename <old> <new>' >&2
        return 1
    end

    set -l main_root (__gwt_main_root)
    set -l repo_name (basename "$main_root")
    set -l old_path (__gwt_branch_to_path "$old_name")

    if test -z "$old_path"
        echo "No worktree found for branch: $old_name" >&2
        return 1
    end

    set -l new_path (dirname "$main_root")/worktree/$new_name

    if test -d "$new_path"
        echo "Path already exists: $new_path" >&2
        return 1
    end

    git worktree move "$old_path" "$new_path"
    or return 1

    git branch -m "$old_name" "$new_name"
    or return 1

    tmux kill-session -t "=$repo_name/$old_name" 2>/dev/null

    echo "Renamed: $old_name → $new_name"
end

function __gwt_pick
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l branch ''
    set -l wt_path ''

    if test -n "$argv[1]"
        set wt_path (__gwt_branch_to_path "$argv[1]")
        if test -z "$wt_path"
            echo "No worktree found for branch: $argv[1]" >&2
            return 1
        end
        set branch "$argv[1]"
    else
        set -l branches
        set -l paths

        for line in (git worktree list)
            set -l path (string split -m1 ' ' $line)[1]
            set -l rest (string replace -r '^\S+\s+' '' $line)
            set -l b ''

            if string match -q '(bare)' -- $rest
                continue
            else if string match -qr '\[(.+)\]' $rest
                set b (string match -r '\[(.+)\]' $rest)[2]
            else
                set b '(detached HEAD)'
            end

            set -a branches "$b"
            set -a paths "$path"
        end

        if test (count $branches) -eq 0
            echo 'No worktrees found.' >&2
            return 1
        end

        set -l fzf_input
        for i in (seq 1 (count $branches))
            set -a fzf_input (printf "%s\t%s" "$branches[$i]" "$paths[$i]")
        end

        set -l chosen (printf "%s\n" $fzf_input | \
            fzf \
                --ansi \
                --no-sort \
                --prompt='Switch to worktree> ' \
                --header='Enter to connect' \
                --delimiter='\t' \
                --with-nth='1' \
                --preview="PATH=$PATH /usr/bin/git -C {2} log --oneline --decorate --graph --color=always -20" \
                --preview-window='right:66%:wrap' \
                --layout='reverse')

        if test -z "$chosen"
            return 0
        end

        set -l parts (string split \t "$chosen")
        set branch $parts[1]
        set wt_path $parts[2]
    end

    __gwt_connect "$wt_path" "$branch"
end

function __gwt_ls
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l worktrees (git worktree list)
    set -l main_repo (string split -m1 ' ' (echo $worktrees[1]))[1]

    set -l col_branch
    set -l col_sync
    set -l col_commit
    set -l is_main

    for line in $worktrees
        set -l path (string split -m1 ' ' $line)[1]
        set -l rest (string replace -r '^\S+\s+' '' $line)
        set -l branch ''

        if string match -q '(bare)' -- $rest
            continue
        else if string match -qr '\[(.+)\]' $rest
            set branch (string match -r '\[(.+)\]' $rest)[2]
        else
            set branch '(detached HEAD)'
        end

        # Ahead/behind
        set -l sync '-'
        set -l ab (git -C "$path" rev-list --left-right --count "HEAD...@{upstream}" 2>/dev/null)
        if test -n "$ab"
            set -l ahead (string split \t "$ab")[1]
            set -l behind (string split \t "$ab")[2]
            set sync "↑$ahead ↓$behind"
        end

        # Commit
        set -l hash (git -C "$path" rev-parse --short HEAD 2>/dev/null)
        set -l msg (git -C "$path" log -1 --format='%s' 2>/dev/null)
        set -l max_msg 50
        if test (string length "$msg") -gt $max_msg
            set msg (string sub -l $max_msg "$msg")…
        end
        set -l commit "$hash: $msg"

        set -a col_branch (test "$path" = "$main_repo"; and echo "$branch (main)"; or echo "$branch")
        set -a col_sync "$sync"
        set -a col_commit "$commit"
        if test "$path" = "$main_repo"
            set -a is_main 1
        else
            set -a is_main 0
        end
    end

    # Column widths
    set -l w_branch 8   # "Worktree"
    set -l w_sync 4     # "↑↓"
    set -l w_commit 11  # "Last Commit"
    for i in (seq 1 (count $col_branch))
        if test (string length "$col_branch[$i]") -gt $w_branch
            set w_branch (string length "$col_branch[$i]")
        end
        if test (string length "$col_sync[$i]") -gt $w_sync
            set w_sync (string length "$col_sync[$i]")
        end
        if test (string length "$col_commit[$i]") -gt $w_commit
            set w_commit (string length "$col_commit[$i]")
        end
    end

    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l dim (set_color brblack)
    set -l bold (set_color --bold)
    set -l reset (set_color normal)

    printf "\n%s%-*s  %-*s  %-*s%s\n" "$bold" $w_branch Worktree $w_commit 'Last Commit' $w_sync '↑↓' "$reset"
    printf "%s%-*s  %-*s  %-*s%s\n" "$dim" \
        $w_branch  (printf '%*s' $w_branch  '' | tr ' ' '─') \
        $w_commit  (printf '%*s' $w_commit  '' | tr ' ' '─') \
        $w_sync    (printf '%*s' $w_sync    '' | tr ' ' '─') "$reset"

    for i in (seq 1 (count $col_branch))
        set -l color $yellow
        if test "$is_main[$i]" = 1
            set color $cyan
        end
        printf "%s%-*s  %-*s  %-*s%s\n" "$color" \
            $w_branch  "$col_branch[$i]" \
            $w_commit  "$col_commit[$i]" \
            $w_sync    "$col_sync[$i]" "$reset"
    end
end
