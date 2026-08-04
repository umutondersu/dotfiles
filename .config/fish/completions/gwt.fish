# Fish completions for gwt (git worktree manager)

# Helper: list all worktree branch names
function __gwt_worktree_branches
    git worktree list --porcelain 2>/dev/null | string replace --regex --filter '^branch refs/heads/' ''
end

# Helper: list linked worktree names (excludes main worktree)
function __gwt_worktree_names
    set -l toplevel (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$toplevel"
        return
    end
    git worktree list --porcelain 2>/dev/null \
        | string replace --regex --filter '^worktree\s*' '' \
        | while read -l path
            if test "$path" != "$toplevel"
                basename "$path"
            end
        end
end

# Helper: true when no non-flag argument has been given after the subcommand
function __gwt_mv_needs_old
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
complete -c gwt -n __fish_use_subcommand -a init   -d 'Ensure worktree/ dir is git-ignored'
complete -c gwt -n __fish_use_subcommand -a rm     -d 'Remove worktree (args or fzf)'
complete -c gwt -n __fish_use_subcommand -a ls     -d 'List all worktrees'
complete -c gwt -n __fish_use_subcommand -a mv     -d 'Rename worktree (1 arg renames current)'
complete -c gwt -n __fish_use_subcommand -a pick   -d 'Pick a worktree and connect to its session'

# --- gwt rm: complete with existing worktree branch names and flags ---
complete -c gwt -n '__fish_seen_subcommand_from rm' \
    -a '(__gwt_worktree_branches)' \
    -d 'Branch'
complete -c gwt -n '__fish_seen_subcommand_from rm' -s b -l branch \
    -d 'Also delete the branch'
complete -c gwt -n '__fish_seen_subcommand_from rm' -s f -l force \
    -d 'Force remove even with uncommitted changes'

# --- gwt mv: complete the first arg (old name) only ---
complete -c gwt -n '__fish_seen_subcommand_from mv; and __gwt_mv_needs_old' \
    -a '(__gwt_worktree_names)' \
    -d 'Worktree to rename'

# --- gwt pick: complete with branch names ---
complete -c gwt -n '__fish_seen_subcommand_from pick' \
    -a '(__gwt_worktree_branches)' \
    -d 'Branch'
