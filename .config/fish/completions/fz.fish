# Completions for fz command

# Disable file completions
complete -c fz -f

# Options
complete -c fz -s h -l help -d "Show help message"
complete -c fz -s l -l list -d "List available search types"

# Search types
complete -c fz -n "not __fish_seen_subcommand_from grep file man tldr make journal" -a "grep" -d "Search file contents with ripgrep (default)"
complete -c fz -n "not __fish_seen_subcommand_from grep file man tldr make journal" -a "file" -d "Browse and select files"
complete -c fz -n "not __fish_seen_subcommand_from grep file man tldr make journal" -a "man" -d "Search man pages"
complete -c fz -n "not __fish_seen_subcommand_from grep file man tldr make journal" -a "tldr" -d "Browse tldr pages"
complete -c fz -n "not __fish_seen_subcommand_from grep file man tldr make journal" -a "make" -d "List and run Makefile targets"
complete -c fz -n "not __fish_seen_subcommand_from grep file man tldr make journal" -a "journal" -d "Browse systemd journal logs"
