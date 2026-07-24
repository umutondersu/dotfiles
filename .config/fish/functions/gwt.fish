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
            echo '  add <name>             Create worktree and switch to sesh session'
            echo '  add --jira <KEY>       Fetch Jira summary, create worktree + sesh session'
            echo '  rm [<name>...] [-b] [-f]   Remove worktrees (args or fzf); -b deletes branch, -f forces'
            echo '  ls                     List worktrees'
            echo '  rename <old> <new>     Rename worktree directory and branch'
            echo '  pick                   Pick a worktree and connect to its session'
            return 0
        case '*'
            echo "Unknown subcommand: $cmd" >&2
            gwt --help >&2
            return 1
    end
end

function __gwt_add
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l name ''
    set -l key ''

    if test "$argv[1]" = --jira -o "$argv[1]" = -j
        set key $argv[2]
        if test -z "$key"
            echo 'Missing Jira key.' >&2
            return 1
        end

        set -l prefix ''
        if string match -qr '^(.+)/' $key
            set prefix (string match -r '^(.+)/' $key)[2]
            set key (string replace -r '^.+/' '' $key)
        end

        if set -q JIRA_URL; and set -q JIRA_TOKEN
            set -l resp (curl -s \
                -H "Authorization: Bearer $JIRA_TOKEN" \
                -H 'Accept: application/json' \
                "$JIRA_URL/rest/api/2/issue/$key?fields=summary" 2>&1)

            set -l summary (echo "$resp" | jq -r '.fields.summary')
            if test -z "$summary"; or test "$summary" = null
                echo "Failed to fetch Jira issue: $key" >&2
                echo "$resp" | head -5 >&2
                return 1
            end

            set -l kebab (echo "$summary" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
            set -l max_summary_len 30
            if test (string length "$kebab") -gt $max_summary_len
                set kebab (string sub -l $max_summary_len "$kebab" | sed 's/-[^-]*$//')
            end
            set name "$key-$kebab"
            if test -n "$prefix"
                set name "$prefix/$name"
            end
        else
            echo 'Jira env vars not set. Need: JIRA_URL and JIRA_TOKEN' >&2
            return 1
        end
    else if test -n "$argv[1]"
        set name "$argv[1]"
    else
        echo 'Usage: gwt add <name> | gwt add --jira <KEY>' >&2
        return 1
    end

    set -l common (realpath (git rev-parse --git-common-dir))
    set -l main_root (string replace -r '/\.git(/worktrees/.+)?$' '' "$common")
    set -l repo_name (basename "$main_root")
    set -l wt_path (dirname "$main_root")/worktree/$name
    set -l wt_dir (dirname "$wt_path")
    if not test -d "$wt_dir"
        mkdir -p "$wt_dir"
        or begin
            echo "Failed to create directory: $wt_dir" >&2
            return 1
        end
    end

    # If worktree path already exists, fall through to session connect
    if test -d "$wt_path"
        echo "Worktree already exists: $wt_path"
    else if git show-ref --verify --quiet "refs/heads/$name"
        git worktree add "$wt_path" "$name"
        or return 1
    else
        git worktree add -b "$name" "$wt_path"
        or return 1
    end

    set -l session_name "$repo_name/$name"
    if not tmux has-session -t "$session_name" 2>/dev/null
        tmux new-session -d -s "$session_name" -c "$wt_path"
    end
    sesh connect -s "$session_name"
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

    set -l root (git rev-parse --show-toplevel)
    set -l main_path (git worktree list --porcelain | head -1 | string replace 'worktree ' '')

    set -l paths
    if test (count $names) -gt 0
        for name in $names
            # If it looks like an absolute path use it directly, otherwise resolve
            if string match -q '/*' $name
                set -a paths $name
            else
                set -a paths (dirname "$root")/worktree/$name
            end
        end
    else
        # fzf selection — exclude main worktree
        set -l worktree_lines (git worktree list | grep -v '(bare)')
        set -l filtered
        for line in $worktree_lines
            set -l p (string split -m1 ' ' $line)[1]
            if test "$p" != "$main_path"
                set -a filtered $line
            end
        end

        if test (count $filtered) -eq 0
            echo 'No worktrees to remove.'
            return 0
        end

        set -l chosen (printf "%s\n" $filtered | fzf \
            --multi \
            --ansi \
            --no-sort \
            --prompt='Remove worktrees> ' \
            --header='Tab to multi-select, Enter to confirm')

        if test -z "$chosen"
            return 0
        end

        for line in $chosen
            set -l p (string split -m1 ' ' $line)[1]
            if test -n "$p"
                set -a paths $p
            end
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

        set -l repo_name (basename "$main_root")
        set -l session_name "$repo_name/"(basename "$path")
        if tmux has-session -t "$session_name" 2>/dev/null
            tmux kill-session -t "$session_name"
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

    set -l common (realpath (git rev-parse --git-common-dir))
    set -l main_root (string replace -r '/\.git(/worktrees/.+)?$' '' "$common")
    set -l old_path (dirname "$main_root")/worktree/$old_name
    set -l new_path (dirname "$main_root")/worktree/$new_name

    if not test -d "$old_path"
        echo "Worktree not found: $old_path" >&2
        return 1
    end

    if test -d "$new_path"
        echo "Path already exists: $new_path" >&2
        return 1
    end

    git worktree move "$old_path" "$new_path"
    or return 1

    git branch -m "$old_name" "$new_name"
    or return 1

    tmux kill-session -t "$repo_name/$old_name" 2>/dev/null

    echo "Renamed: $old_name → $new_name"
end

function __gwt_pick
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l common (realpath (git rev-parse --git-common-dir))
    set -l main_root (string replace -r '/\.git(/worktrees/.+)?$' '' "$common")
    set -l repo_name (basename "$main_root")

    set -l branches
    set -l paths

    for line in (git worktree list)
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

        set -a branches "$branch"
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
    set -l branch $parts[1]
    set -l wt_path $parts[2]

    set -l session_name "$repo_name/$branch"

    if not tmux has-session -t "$session_name" 2>/dev/null
        tmux new-session -d -s "$session_name" -c "$wt_path"
    end
    sesh connect -s "$session_name"
end

function __gwt_ls
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l worktrees (git worktree list)
    set -l main_repo (string split -m1 ' ' (echo $worktrees[1]))[1]

    set -l entries
    set -l max_len 0

    for line in $worktrees
        set -l path (string split -m1 ' ' $line)[1]
        set -l rest (string replace -r '^\S+\s+' '' $line)
        set -l branch ''
        set -l bare ''

        if string match -q '(bare)' -- $rest
            set bare ' (bare)'
            set branch bare
        else if string match -qr '\[(.+)\]' $rest
            set branch (string match -r '\[(.+)\]' $rest)[2]
        else
            set branch (detached HEAD)
        end

        set -a entries "$path|$branch|$bare"

        if test (string length "$branch") -gt $max_len
            set max_len (string length "$branch")
        end
    end

    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l dim (set_color brblack)
    set -l bold (set_color --bold)
    set -l reset (set_color normal)

    printf "%s%-*s  %s%s\n" "$bold" $max_len Branch Path "$reset"
    printf "%s%-*s  %s%s\n" "$dim" $max_len (printf '%*s' $max_len '' | tr ' ' '─') (printf '%.0s─' (seq 1 40)) "$reset"

    for entry in $entries
        set -l parts (string split '|' $entry)
        set -l path $parts[1]
        set -l branch $parts[2]
        set -l bare $parts[3]

        if test "$path" = "$main_repo"
            printf "%s%-*s  %s%s\n" "$cyan" $max_len "$branch" "$path$bare" "$reset"
        else
            printf "%s%-*s  %s%s\n" "$yellow" $max_len "$branch" "$path$bare" "$reset"
        end
    end
end
