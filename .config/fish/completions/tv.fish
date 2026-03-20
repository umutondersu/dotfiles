# Completions for tv command

# Options
complete -c tv -f -s h -l help -d "Show help message"
complete -c tv -f -s l -l list -d "List available search types"

# Search types (disable file completions for these) - keep these at higher priority
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a grep -d "Search file contents with ripgrep (default)"
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a file -d "Browse and select files"
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a man -d "Search man pages"
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a tldr -d "Browse tldr pages"
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a cht -d "Browse cht.sh cheat sheets"
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a make -d "List and run Makefile targets"
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a journal -d "Browse systemd journal logs"
complete -c tv -f -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -eq 1" -a ps -d "Browse running processes"

# Enable file completion when no subcommand (defaults to grep mode) - only if current word looks like a path
complete -c tv -n "not __fish_seen_subcommand_from grep file man tldr cht make journal ps; and test (count (commandline -opc)) -ge 1; and string match -qr '[./]' -- (commandline -ct)" -F -d "File to search in (optional)"

# Enable file completion for second argument after 'grep'
complete -c tv -n "__fish_seen_subcommand_from grep; and test (count (commandline -opc)) -eq 2" -F -d "File to search in (optional)"

# Enable file completion for second argument after 'file'
complete -c tv -n "__fish_seen_subcommand_from file; and test (count (commandline -opc)) -eq 2" -F -d "File to search for (optional)"

# Disable file completion for other search types (only show custom completions)
complete -c tv -f -n "__fish_seen_subcommand_from man tldr cht make journal ps"
