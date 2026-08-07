function gwt --description 'Git worktree manager'
    set -l cmd $argv[1]
    set -e argv[1]

    switch "$cmd"
        case add
            __gwt_add $argv
        case init
            __gwt_init
        case rm
            __gwt_rm $argv
        case ls
            __gwt_ls $argv
        case mv
            __gwt_mv $argv
        case pick
            __gwt_pick $argv
        case '' -h --help
            echo 'Usage: gwt <subcommand>'
            echo ''
            echo 'Subcommands:'
            echo '  add [<name>] [-b <base>]       Create worktree (no arg picks remote branch; -b sets base)'
            echo '  init                           Ensure worktree/ dir is git-ignored'
            echo '  ls                             List worktrees'
            echo '  mv [<old>] <new> [-B]          Move worktree dir; renames branch if it matches, -B keeps it'
            echo '  pick [<name>]                  Pick a worktree and connect to its session'
            echo '  rm [. | <name>...] [-B] [-f]   Remove worktrees; -B keeps branch, -f forces dirty'
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

# A worktree's identity is its NAME: the directory path relative to the main
# repo's worktree/ dir (the repo basename for the main worktree itself). The
# branch a worktree checks out is incidental and must never be used as its key.

# Given a worktree name (dir name under worktree/, or absolute path), prints its
# absolute path. Prints nothing if it isn't a registered worktree.
function __gwt_name_to_path --argument-names name main_root
    if string match -q '/*' -- "$name"
        echo $name
        return 0
    end
    set -l p "$main_root"/worktree/$name
    if git worktree list --porcelain | string match -q -- "worktree $p"
        echo $p
    end
end

# Given a worktree absolute path, prints its name (relative to the main repo's
# worktree/ dir; the repo basename for the main worktree).
function __gwt_path_to_name --argument-names path main_root
    if test "$path" = "$main_root"
        basename "$main_root"
    else
        string replace -r '^.*/worktree/' '' "$path"
    end
end

# Ensure the worktree dir inside the repo is git-ignored (idempotent) so it
# never shows up as untracked in the main working tree.
function __gwt_ignore_worktree_dir --argument-names main_root
    set -l exclude "$main_root/.git/info/exclude"
    if not string match -q -- worktree/ (command cat "$exclude" 2>/dev/null)
        echo worktree/ >>"$exclude"
    end
end

function __gwt_init
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l main_root (__gwt_main_root)
    __gwt_ignore_worktree_dir "$main_root"

    echo "worktree/ is git-ignored in $main_root"
end

# Connect to the tmux session for a worktree (keyed by its directory name),
# creating it if needed.
function __gwt_connect
    set -l wt_path $argv[1]
    set -l main_root (__gwt_main_root)
    set -l repo_name (basename "$main_root")
    set -l wt_name (__gwt_path_to_name "$wt_path" "$main_root")

    set -l session_name (test "$wt_path" = "$main_root"; and echo "$repo_name"; or echo "$repo_name/$wt_name")
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
    set -l name ''
    set -l base ''

    set -l i 1
    while test $i -le (count $argv)
        switch "$argv[$i]"
            case -b --base
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set base $argv[$i]
                end
            case '*'
                if test -z "$name"
                    set name $argv[$i]
                end
        end
        set i (math $i + 1)
    end

    # No name given: fetch origin and pick a remote branch via fzf
    set -l already_fetched 0
    if test -z "$name"
        echo 'Fetching origin...'
        git fetch --prune origin >/dev/null 2>&1
        or begin
            echo 'Failed to fetch origin.' >&2
            return 1
        end
        set already_fetched 1

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

        set name (string split \t "$chosen")[1]
    end

    # Worktree already exists for this name: connect to it like gwt pick
    set -l existing_wt (__gwt_name_to_path "$name" "$main_root")
    if test -n "$existing_wt"
        __gwt_connect "$existing_wt"
        return 0
    end

    set -l wt_path "$main_root"/worktree/$name
    set -l wt_dir "$main_root"/worktree

    if not test -d "$wt_dir"
        mkdir -p "$wt_dir"
        or begin
            echo "Failed to create directory: $wt_dir" >&2
            return 1
        end
        __gwt_ignore_worktree_dir "$main_root"
    end

    if git show-ref --verify --quiet "refs/heads/$name"
        git worktree add "$wt_path" "$name" >/dev/null 2>&1
        or return 1
    else if test $already_fetched -eq 1; or git ls-remote --exit-code origin "$name" &>/dev/null
        # Branch exists on origin: fetch it if we haven't already, then create with tracking
        if test $already_fetched -eq 0
            echo "Fetching origin/$name..."
            git fetch origin "$name" >/dev/null 2>&1
            or begin
                echo "Failed to fetch origin/$name." >&2
                return 1
            end
        end
        git worktree add --track -b "$name" "$wt_path" "origin/$name" >/dev/null 2>&1
        or return 1
    else
        # Default base: the branch checked out in the main worktree
        if test -z "$base"
            set base (git -C "$main_root" symbolic-ref --short HEAD 2>/dev/null)
        end
        git worktree add -b "$name" "$wt_path" "$base" >/dev/null 2>&1
        or return 1
    end

    __gwt_connect "$wt_path"
end

function __gwt_rm
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l delete_branch 1
    set -l force 0
    set -l names

    for arg in $argv
        switch "$arg"
            case -B --keep-branch
                set delete_branch 0
            case -f --force
                set force 1
            case '*'
                set -a names $arg
        end
    end

    set -l main_path (git worktree list --porcelain | head -1 | string replace 'worktree ' '')

    # Resolve names to absolute worktree paths. Names are directory names:
    # '.' = current worktree, '/abs/path' = path, otherwise a dir under worktree/.
    set -l paths
    set -l fzf_selected_paths # paths chosen via fzf — dirty ones are auto-forced
    if test (count $names) -gt 0
        for name in $names
            if test "$name" = '.'
                set -l cur_path (git rev-parse --show-toplevel 2>/dev/null)
                if test "$cur_path" = "$main_path"
                    echo 'Cannot remove the main worktree.' >&2
                    return 1
                end
                set -a paths $cur_path
            else if string match -q '/*' -- $name
                set -a paths $name
            else
                set -l match (__gwt_name_to_path "$name" (__gwt_main_root))
                if test -z "$match"
                    echo "No worktree found: $name" >&2
                    continue
                end
                set -a paths $match
            end
        end
    else
        # Build worktree-name list including dirty worktrees; skip only main
        set -l names
        set -l fzf_paths
        set -l main_root (__gwt_main_root)

        for line in (git worktree list)
            set -l path (string split -m1 ' ' $line)[1]
            set -l rest (string replace -r '^\S+\s+' '' $line)

            if string match -q '(bare)' -- $rest
                continue
            else if test "$path" = "$main_path"
                continue
            end

            set -a names (__gwt_path_to_name "$path" "$main_root")
            set -a fzf_paths "$path"
        end

        if test (count $names) -eq 0
            echo 'No worktrees to remove.'
            return 0
        end

        set -l fzf_input
        for i in (seq 1 (count $names))
            set -a fzf_input (printf "%s\t%s" "$names[$i]" "$fzf_paths[$i]")
        end

        # Write preview script to a temp file so fzf runs it via sh, avoiding
        # fish parsing issues with $() subshell syntax in --preview strings.
        set -l preview_script (mktemp /tmp/gwt_preview_XXXXXX)
        printf '#!/bin/sh\nPATH=%s\ngit=%s\npath="$1"\ndirty=$("$git" -C "$path" status --porcelain 2>/dev/null)\nif [ -n "$dirty" ]; then\n  echo "--- Uncommitted changes ---"\n  "$git" -C "$path" status --short\n  echo "--- Log ---"\nfi\n"$git" -C "$path" log --oneline --decorate --graph --color=always -20\n' \
            "$PATH" /usr/bin/git >"$preview_script"
        chmod +x "$preview_script"

        set -l chosen (printf "%s\n" $fzf_input | fzf \
            --multi \
            --ansi \
            --no-sort \
            --prompt='Remove worktrees> ' \
            --header='Tab to multi-select, Enter to confirm' \
            --delimiter='\t' \
            --with-nth='1' \
            --preview="$preview_script {2}" \
            --preview-window='right:66%:wrap' \
            --layout='reverse')

        command rm -f "$preview_script"

        if test -z "$chosen"
            return 0
        end
        for line in $chosen
            set -l parts (string split \t "$line")
            set -a fzf_selected_paths $parts[2]
        end
    end

    # Merge: named paths require explicit -f for dirty; fzf paths are auto-forced
    set -l all_paths $paths $fzf_selected_paths

    # Pre-check named paths only: verify valid + not dirty (unless -f)
    for path in $paths
        if not git worktree list --porcelain | string match -q -- "worktree $path"
            echo "Not a worktree: $path" >&2
            return 1
        end
        if test $force -eq 0
            set -l dirty (git -C "$path" status --porcelain 2>/dev/null)
            if test -n "$dirty"
                echo "Worktree has uncommitted changes (use -f to force): $path" >&2
                return 1
            end
        end
    end
    # Pre-check fzf paths: verify valid only (dirty is fine — auto-forced below)
    for path in $fzf_selected_paths
        if not git worktree list --porcelain | string match -q -- "worktree $path"
            echo "Not a worktree: $path" >&2
            return 1
        end
    end

    for path in $all_paths
        # Snapshot tmux state before the worktree is removed, since once its cwd is
        # deleted the running shell's pane path can no longer be read reliably.
        set -l cur_pane_id (tmux display-message -p '#{pane_id}' 2>/dev/null)
        set -l cur_pane_path (tmux display-message -p '#{pane_current_path}' 2>/dev/null)
        set -l cur_session (tmux display-message -p '#{session_name}' 2>/dev/null)

        # Resolve branch name before removing the worktree
        set -l branch ''
        if test $delete_branch -eq 1
            set branch (git worktree list --porcelain | awk -v p="$path" '
                /^worktree / { cur = substr($0, 10) }
                cur == p && /^branch / { sub("refs/heads/", "", $2); print $2 }
            ')
        end

        # Auto-force if: -f flag set, OR path came from fzf and is dirty
        set -l rm_args
        if test $force -eq 1
            set rm_args --force
        else if contains -- $path $fzf_selected_paths
            set -l dirty (git -C "$path" status --porcelain 2>/dev/null)
            if test -n "$dirty"
                set rm_args --force
            end
        end

        git worktree remove $rm_args "$path"
        or return 1

        echo "Removed: $path"

        # Remove parent dirs that are now empty (e.g. feat/ after feat/branch is deleted)
        set -l parent (dirname "$path")
        while test "$parent" != (dirname "$parent")
            if test -d "$parent" && test (count (command ls -A "$parent")) -eq 0
                rmdir "$parent"
                set parent (dirname "$parent")
            else
                break
            end
        end

        if test $delete_branch -eq 1 -a -n "$branch"
            # Use the full ref and git update-ref so branch names like `origin/x`
            # (ambiguous with the remote-tracking ref) resolve to the local branch
            # instead of making `git branch -d` abort. Run from the main repo
            # since `gwt rm .` leaves the shell's cwd inside a removed worktree.
            set -l branch_ref "refs/heads/$branch"

            set -l merged 0
            if git -C "$main_path" merge-base --is-ancestor "$branch_ref" HEAD 2>/dev/null
                set merged 1
            else if set -l upstream (git -C "$main_path" rev-parse --quiet --abbrev-ref "$branch@{upstream}" 2>/dev/null); and test -n "$upstream"
                if git -C "$main_path" merge-base --is-ancestor "$branch_ref" "$upstream" 2>/dev/null
                    set merged 1
                end
            end

            if test $merged -eq 0
                read -l -P "Branch '$branch' is not fully merged. Force delete? [y/N] " confirm
                if not string match -qi y "$confirm"
                    echo "Kept branch: $branch"
                    continue
                end
            end

            git -C "$main_path" update-ref -d "$branch_ref"
            and echo "Deleted branch: $branch"
        end

        # Kill leftover non-current sessions whose panes live inside the removed
        # worktree (e.g. its dedicated repo/<name> session removed from afar).
        # Use pane_current_path (live cwd) rather than the stale session_path.
        for sess in (tmux list-panes -a -F '#{session_name} #{pane_current_path}' 2>/dev/null \
                | awk -v p="$path" '$2 == p {print $1}' | sort -u)
            if test "$sess" != "$cur_session"
                tmux kill-session -t "=$sess" 2>/dev/null
                echo "Killed session: $sess"
            end
        end

        # Handle the session we are running in, when the current pane sits inside
        # the removed worktree. Must be last: it either kills or replaces this
        # shell. A dedicated gwt session (repo/<name>) is terminated; a generic
        # pane parked in the worktree is relocated to the main repo instead.
        if test -n "$cur_pane_path"; and test "$cur_pane_path" = "$path"
            set -l repo_name (basename "$main_path")
            set -l wt_name (__gwt_path_to_name "$path" "$main_path")
            if test "$cur_session" = "$repo_name/$wt_name"
                tmux kill-session -t "=$cur_session" 2>/dev/null
            else
                tmux respawn-pane -t "$cur_pane_id" -k -c "$main_path" 2>/dev/null
            end
        end
    end
end

function __gwt_mv
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l main_root (__gwt_main_root)
    set -l repo_name (basename "$main_root")

    set -l keep_branch 0
    set -l positional
    for arg in $argv
        switch "$arg"
            case -B --keep-branch
                set keep_branch 1
            case '*'
                set -a positional $arg
        end
    end

    set -l old_name $positional[1]
    set -l new_name $positional[2]

    if test -z "$old_name"
        echo 'Usage: gwt mv [<old>] <new> [-B]' >&2
        return 1
    end

    if test -z "$new_name"
        # Single arg: rename the current worktree (its dir name)
        set rename_current 1
        set new_name $old_name
        set -l current_path (git rev-parse --show-toplevel)
        if test "$current_path" = "$main_root"
            echo 'Cannot rename the main worktree.' >&2
            return 1
        end
        set old_name (__gwt_path_to_name "$current_path" "$main_root")
    else
        set rename_current 0
    end

    set -l old_path (__gwt_name_to_path "$old_name" "$main_root")

    if test -z "$old_path"
        echo "No worktree found: $old_name" >&2
        return 1
    end

    set -l new_path "$main_root"/worktree/$new_name

    if test -d "$new_path"
        echo "Path already exists: $new_path" >&2
        return 1
    end

    # Branch name before moving — used to decide whether to rename it with the dir.
    set -l branch (git -C "$old_path" symbolic-ref --short HEAD 2>/dev/null)

    # Sessions are keyed by directory name, so a branch rename never touches them.
    set -l old_sess "$repo_name/$old_name"
    set -l new_sess "$repo_name/$new_name"

    # The pane whose cwd is the worktree becomes unable to run tmux once the dir is
    # moved out from under it, so rename sessions and capture the pane id BEFORE
    # moving. respawn must run after the move (the shell may be mid-dead-cwd).
    if test "$rename_current" = 1
        if test "$old_name" != "$new_name"
            tmux rename-session -t "=$old_sess" "$new_sess" 2>/dev/null
        end
        set -l cur_pane_id (tmux display-message -p '#{pane_id}' 2>/dev/null)
    else if tmux list-sessions -F '#{session_name}' 2>/dev/null | string match -q -- "$old_sess"
        tmux rename-session -t "=$old_sess" "$new_sess" 2>/dev/null
        set renamed_other_session 1
    end

    git worktree move "$old_path" "$new_path"
    or return 1

    # The worktree's identity is its directory; the branch is renamed to match
    # only when it still carries the old dir name (i.e. was created by `gwt add`)
    # and -B/--keep-branch wasn't given.
    if test $keep_branch -eq 0 -a -n "$branch"; and test "$branch" = "$old_name"
        git -C "$main_root" branch -m "$branch" "$new_name"
        and echo "Renamed branch: $branch → $new_name"
    else if test $keep_branch -eq 1 -a -n "$branch"
        echo "Kept branch: $branch"
    end
    echo "Moved: $old_path → $new_path"

    # Prune empty parent dirs left behind by the move (e.g. feat/ after feat/branch).
    set -l parent (dirname "$old_path")
    while test "$parent" != (dirname "$parent")
        if test -d "$parent" && test (count (command ls -A "$parent")) -eq 0
            rmdir "$parent"
            set parent (dirname "$parent")
        else
            break
        end
    end

    # Respawn panes into the new directory. Must be the last actions: for the
    # rename-current case respawn replaces the very shell running this function.
    if test "$rename_current" = 1
        tmux respawn-pane -t "$cur_pane_id" -k -c "$new_path" 2>/dev/null
    else if test "$renamed_other_session" = 1
        for pane in (tmux list-panes -t "=$new_sess" -F '#{pane_id}' 2>/dev/null)
            tmux respawn-pane -t "$pane" -k -c "$new_path" 2>/dev/null
        end
    end
end

function __gwt_pick
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l main_root (__gwt_main_root)
    set -l wt_path ''

    if test -n "$argv[1]"
        set wt_path (__gwt_name_to_path "$argv[1]" "$main_root")
        if test -z "$wt_path"
            echo "No worktree found: $argv[1]" >&2
            return 1
        end
    else
        set -l names
        set -l paths

        for line in (git worktree list)
            set -l path (string split -m1 ' ' $line)[1]
            set -l rest (string replace -r '^\S+\s+' '' $line)

            if string match -q '(bare)' -- $rest
                continue
            end

            set -l name (__gwt_path_to_name "$path" "$main_root")
            if test "$path" = "$main_root"
                set name "$name (main)"
            end
            set -a names "$name"
            set -a paths "$path"
        end

        if test (count $names) -eq 0
            echo 'No worktrees found.' >&2
            return 1
        end

        set -l fzf_input
        for i in (seq 1 (count $names))
            set -a fzf_input (printf "%s\t%s" "$names[$i]" "$paths[$i]")
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
        set wt_path $parts[2]
    end

    __gwt_connect "$wt_path"
end

function __gwt_ls
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l worktrees (git worktree list)
    set -l main_repo (string split -m1 ' ' (echo $worktrees[1]))[1]
    set -l main_root (__gwt_main_root)

    set -l col_name
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

        # Identity is the directory name; the branch is secondary.
        set -l name (__gwt_path_to_name "$path" "$main_root")

        # Ahead/behind
        set -l sync -
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

        set -a col_name (test "$path" = "$main_repo"; and echo "$name (main)"; or echo "$name")
        set -a col_branch "$branch"
        set -a col_sync "$sync"
        set -a col_commit "$commit"
        if test "$path" = "$main_repo"
            set -a is_main 1
        else
            set -a is_main 0
        end
    end

    # Column widths
    set -l w_name 8 # "Worktree"
    set -l w_branch 6 # "Branch"
    set -l w_sync 4 # "↑↓"
    set -l w_commit 11 # "Last Commit"
    for i in (seq 1 (count $col_name))
        if test (string length "$col_name[$i]") -gt $w_name
            set w_name (string length "$col_name[$i]")
        end
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

    printf "\n%s%-*s  %-*s  %-*s  %-*s%s\n" "$bold" $w_name Worktree $w_branch Branch $w_commit 'Last Commit' $w_sync '↑↓' "$reset"
    printf "%s%-*s  %-*s  %-*s  %-*s%s\n" "$dim" \
        $w_name (printf '%*s' $w_name   '' | tr ' ' '─') \
        $w_branch (printf '%*s' $w_branch '' | tr ' ' '─') \
        $w_commit (printf '%*s' $w_commit '' | tr ' ' '─') \
        $w_sync (printf '%*s' $w_sync   '' | tr ' ' '─') "$reset"

    for i in (seq 1 (count $col_name))
        set -l color $yellow
        if test "$is_main[$i]" = 1
            set color $cyan
        end
        printf "%s%-*s  %-*s  %-*s  %-*s%s\n" "$color" \
            $w_name "$col_name[$i]" \
            $w_branch "$col_branch[$i]" \
            $w_commit "$col_commit[$i]" \
            $w_sync "$col_sync[$i]" "$reset"
    end
end
