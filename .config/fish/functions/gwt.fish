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
        case '' -h --help
            echo 'Usage: gwt <subcommand>'
            echo ''
            echo 'Subcommands:'
            echo '  add <name>             Create worktree and switch to sesh session'
            echo '  add --jira <KEY>       Fetch Jira summary, create worktree + sesh session'
            echo '  rm                     Remove worktrees (fzf multi-select)'
            echo '  ls                     List worktrees'
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

    git worktree add -b "$name" "../$name"
    or return 1

    sesh connect -s (realpath "../$name")
end

function __gwt_rm
    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo 'Not inside a git repository.' >&2
        return 1
    end

    set -l worktrees (git worktree list | grep -v '(bare)')
    if test -z "$worktrees"
        echo 'No worktrees to remove.'
        return 0
    end

    set -l chosen (printf "%s\n" $worktrees | fzf \
        --multi \
        --ansi \
        --no-sort \
        --prompt='Remove worktrees> ' \
        --header='Tab to multi-select, Enter to confirm')

    if test -z "$chosen"
        return 0
    end

    set -l paths
    for line in $chosen
        set -l path (string split -m1 ' ' $line)[1]
        if test -n "$path"
            set -a paths $path
        end
    end

    for path in $paths
        git worktree remove "$path" 2>/dev/null
        and echo "Removed: $path"
    end
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
            set branch 'bare'
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

    printf "%s%-*s  %s%s\n" "$bold" $max_len "Branch" "Path" "$reset"
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
