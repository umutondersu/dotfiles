# Completions for fz command

# Options
complete -c fz -f -s h -l help -d "Show help message"
complete -c fz -f -s l -l list -d "List available search types"

# Search types (disable file completions for these)
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "grep" -d "Search file contents with ripgrep (default)"
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "file" -d "Browse and select files"
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "man" -d "Search man pages"
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "tldr" -d "Browse tldr pages"
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "cht" -d "Browse cht.sh cheat sheets"
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "make" -d "List and run Makefile targets"
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "journal" -d "Browse systemd journal logs"
complete -c fz -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps" -a "ps" -d "Browse running processes"

# Enable file completion for second argument after 'grep'
complete -c fz -n "__fish_seen_subcommand_from grep" -F -d "File to search in"
