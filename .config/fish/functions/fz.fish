function fz
    set -l search_type $argv[1]

    # Show list of available types
    if test "$search_type" = --list; or test "$search_type" = -l; or test "$search_type" = --help; or test "$search_type" = -h
        echo "Available search types:"
        echo "  grep    - Search file contents with ripgrep (default)"
        echo "  file    - Browse and select files"
        echo "  man     - Search man pages"
        echo "  tldr    - Browse tldr pages"
        echo "  make    - List and run Makefile targets"
        echo "  journal - Browse systemd journal logs"
        return 0
    end

    # Default to grep if no argument provided
    if test -z "$search_type"
        set search_type grep
    end

    set -l cols (tput cols)
    set -l lines (tput lines)

    # If narrow (fewer than 100 columns) or portrait, use vertical layout
    if test $cols -lt 100; or test $lines -gt $cols
        set preview_pos 'down:50%'
    else
        set preview_pos 'right:50%'
    end

    # Common fzf options
    set -l common_opts --ansi \
        --layout=reverse \
        --preview-window $preview_pos \
        --bind 'ctrl-/:change-preview-window(down:50%|right:50%)'

    if test "$search_type" = man
        apropos . | fzf $common_opts \
            --delimiter ' ' \
            --preview 'man {1} 2>/dev/null | bat --style=plain --language=man --color=always' \
            --bind 'enter:become(man {1})'
    else if test "$search_type" = grep
        fzf $common_opts \
            --disabled \
            --bind "change:reload:rg --color=always --line-number --no-heading --smart-case {q} || true" \
            --delimiter : \
            --preview 'test -n "{1}" && bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || echo "Type to search files..."' \
            --bind 'enter:become(nvim {1} +{2} -c "normal! zz")'
    else if test "$search_type" = file
        fd --type f --hidden --exclude .git | fzf $common_opts \
            --preview 'bat --style=numbers --color=always {}' \
            --bind 'enter:become(nvim {})'
    else if test "$search_type" = tldr
        tldr --list | fzf $common_opts \
            --preview 'tldr {} --color' \
            --bind 'enter:become(tldr {})'
    else if test "$search_type" = make
        make -pRrq 2>/dev/null | awk -F: '/^[a-zA-Z0-9][^$#\/\\t=]*:([^=]|$)/ {split($1,a," "); print a[1]}' | sort -u | grep -v '^Makefile$' | fzf $common_opts \
            --preview "awk '/^{}[[:space:]]*:/{found=1} found{print; if(/^[^\\t]/ && NR>1 && !/^{}[[:space:]]*:/) exit}' Makefile | bat --style=plain --language=make --color=always" \
            --bind 'enter:become(make {})'
    else if test "$search_type" = journal
        journalctl --field SYSLOG_IDENTIFIER 2>/dev/null | sort -f | fzf $common_opts \
            --preview "journalctl -b --no-pager -o short-iso -n 50 SYSLOG_IDENTIFIER='{}' 2>/dev/null" \
            --bind 'enter:become(journalctl -f SYSLOG_IDENTIFIER='"'"'{}'"'"')'
    else
        echo "Unknown search type: $search_type"
        echo ""
        echo "Available search types:"
        echo "  grep    - Search file contents with ripgrep (default)"
        echo "  file    - Browse and select files"
        echo "  man     - Search man pages"
        echo "  tldr    - Browse tldr pages"
        echo "  make    - List and run Makefile targets"
        echo "  journal - Browse systemd journal logs"
        return 0
    end
end
