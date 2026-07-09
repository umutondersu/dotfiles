# Fish completions for gwt (git worktree manager)

# Helper: list linked worktree names under <repo>/worktrees/.
# Excludes the main/bare worktree.
function __gwt_worktree_names
    set -l toplevel (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$toplevel"
        return
    end
    set -l wt_root "$toplevel/worktrees"
    git worktree list --porcelain 2>/dev/null \
        | string replace --regex --filter '^worktree\s*' '' \
        | while read -l path
            if test "$path" != "$toplevel"
                string replace "$wt_root/" "" "$path"
            end
        end
end

# Helper: true when no non-flag argument has been given after the subcommand
# (i.e., we still need the <old> name for gwt rename)
function __gwt_rename_needs_old
    set -l tokens (commandline -pxc)
    set -l count 0
    for tok in $tokens[3..]
        if not string match -q -- '-*' $tok
            set count (math $count + 1)
        end
    end
    test $count -lt 1
end

# Disable file completions globally for gwt
complete -c gwt -f

# --- Subcommands ---
complete -c gwt -n __fish_use_subcommand -a add    -d 'Create a worktree and open a sesh session'
complete -c gwt -n __fish_use_subcommand -a rm     -d 'Remove worktrees (fzf multi-select)'
complete -c gwt -n __fish_use_subcommand -a ls     -d 'List all worktrees'
complete -c gwt -n __fish_use_subcommand -a rename -d 'Rename worktree directory and branch'

# --- gwt add: --jira flag ---
complete -c gwt -n '__fish_seen_subcommand_from add' -s j -l jira -r \
    -d 'Fetch Jira summary and use as branch/worktree name'

# --- gwt rm: complete with existing worktree names ---
complete -c gwt -n '__fish_seen_subcommand_from rm' \
    -a '(__gwt_worktree_names)' \
    -d 'Worktree'

# --- gwt rename: complete the first arg (old name) only ---
complete -c gwt -n '__fish_seen_subcommand_from rename; and __gwt_rename_needs_old' \
    -a '(__gwt_worktree_names)' \
    -d 'Worktree to rename'
