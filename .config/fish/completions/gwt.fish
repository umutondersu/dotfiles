# Fish completions for gwt (git worktree manager)

# Helper: list linked worktree directory names (relative to the worktree/ dir,
# so nested names like feat/foo work). Excludes the main worktree.
function __gwt_worktree_names
    # Resolve the main repo path the same way gwt itself does (realpath the
    # git-common-dir), otherwise --git-common-dir is relative (e.g. `.git`) inside
    # the main worktree and the main repo would not be excluded below.
    set -l main_root (string replace -r '/\.git(/worktrees/.+)?$' '' (realpath (git rev-parse --git-common-dir 2>/dev/null)))
    if test -z "$main_root"
        return
    end
    git worktree list --porcelain 2>/dev/null \
        | string replace --regex --filter '^worktree\s*' '' \
        | while read -l path
            if test "$path" != "$main_root"
                string replace --regex '^.*/worktree/' '' "$path"
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

# Helper: true when at least one non-flag argument has been given after rm
function __gwt_rm_has_arg
    set -l tokens (commandline -pxc)
    set -l count 0
    for tok in $tokens[3..]
        if not string match -q -- '-*' $tok
            set count (math $count + 1)
        end
    end
    test $count -ge 1
end

# Helper: list local and remote branch names for --from completion
function __gwt_all_branches
    git branch --format='%(refname:short)' 2>/dev/null
    git branch -r --format='%(refname:short)' 2>/dev/null | string replace 'origin/' ''
end

# Disable file completions globally for gwt
complete -c gwt -f

# --- Subcommands ---
complete -c gwt -n __fish_use_subcommand -a add    -d 'Create worktree (no arg picks remote branch; -b branch name, -f start point)'
complete -c gwt -n __fish_use_subcommand -a completion -d 'Generate the autocompletion script for the specified shell'
complete -c gwt -n __fish_use_subcommand -a init   -d 'Ensure worktree/ dir is git-ignored'
complete -c gwt -n __fish_use_subcommand -a ls     -d 'List worktrees'
complete -c gwt -n __fish_use_subcommand -a mv     -d 'Move worktree dir; renames branch if it matches, -B keeps it'
complete -c gwt -n __fish_use_subcommand -a pick   -d 'Pick a worktree and connect to its session'
complete -c gwt -n __fish_use_subcommand -a rm     -d 'Remove worktrees; -B keeps branch, -f forces dirty'
complete -c gwt -n __fish_use_subcommand -a version -d 'Print version information'

# --- gwt completion: shells ---
complete -c gwt -n '__fish_seen_subcommand_from completion' -a bash -d 'Generate the autocompletion script for bash'
complete -c gwt -n '__fish_seen_subcommand_from completion' -a zsh -d 'Generate the autocompletion script for zsh'
complete -c gwt -n '__fish_seen_subcommand_from completion' -a fish -d 'Generate the autocompletion script for fish'
complete -c gwt -n '__fish_seen_subcommand_from completion' -a powershell -d 'Generate the autocompletion script for powershell'

# --- gwt add: branch name arg (remote branches), -b branch, -f start point ---
complete -c gwt -n '__fish_seen_subcommand_from add' \
    -a '(git branch -r --format="%(refname:short)" 2>/dev/null | string replace "origin/" "")' \
    -d 'Remote branch'
complete -c gwt -n '__fish_seen_subcommand_from add' -s f -l from \
    -d 'Start point' -r \
    -a '(__gwt_all_branches)'
complete -c gwt -n '__fish_seen_subcommand_from add' -s b -l branch \
    -d 'Branch name' -r

# --- gwt rm: complete with existing worktree names and flags ---
complete -c gwt -n '__fish_seen_subcommand_from rm' \
    -a '(__gwt_worktree_names)' \
    -d 'Worktree'
complete -c gwt -n '__fish_seen_subcommand_from rm' -s B -l keep-branch \
    -d 'Keep the branch'
complete -c gwt -n '__fish_seen_subcommand_from rm' -s f -l force \
    -d 'Force removal of dirty worktrees'
# after a worktree is given, cycle the flags into the tab pager too
complete -c gwt -n '__fish_seen_subcommand_from rm; and __gwt_rm_has_arg' -a '-B' -d 'Keep the branch'
complete -c gwt -n '__fish_seen_subcommand_from rm; and __gwt_rm_has_arg' -a '--keep-branch' -d 'Keep the branch'
complete -c gwt -n '__fish_seen_subcommand_from rm; and __gwt_rm_has_arg' -a '-f' -d 'Force removal of dirty worktrees'
complete -c gwt -n '__fish_seen_subcommand_from rm; and __gwt_rm_has_arg' -a '--force' -d 'Force removal of dirty worktrees'

# --- gwt mv: complete the first arg (old name) only ---
complete -c gwt -n '__fish_seen_subcommand_from mv; and __gwt_mv_needs_old' \
    -a '(__gwt_worktree_names)' \
    -d 'Worktree to rename'
complete -c gwt -n '__fish_seen_subcommand_from mv' -s B -l keep-branch \
    -d 'Keep the branch name'

# --- gwt pick: complete with worktree names ---
complete -c gwt -n '__fish_seen_subcommand_from pick' \
    -a '(__gwt_worktree_names)' \
    -d 'Worktree'
