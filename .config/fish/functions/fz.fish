function fz
    set -l search_type $argv[1]
    set -l target_file $argv[2]

    # Show list of available types
    if test "$search_type" = --list; or test "$search_type" = -l; or test "$search_type" = --help; or test "$search_type" = -h
        echo "Available search types:"
        echo "  grep [file]  - Search file contents with ripgrep (default)"
        echo "  file         - Browse and select files"
        echo "  man          - Search man pages"
        echo "  tldr         - Browse tldr pages"
        echo "  cht          - Browse cht.sh cheat sheets"
        echo "  make         - List and run Makefile targets"
        echo "  journal      - Browse systemd journal logs"
        echo "  ps           - Browse running processes"
        return 0
    end

    # If search_type is a file path, use grep mode with that file
    if test -f "$search_type"
        set target_file "$search_type"
        set search_type grep
        # Default to grep if no argument provided
    else if test -z "$search_type"
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
        # If a target file is specified, search only in that file
        if test -n "$target_file"
            rg --color=always --line-number --no-heading '' "$target_file" | fzf $common_opts \
                --ansi \
                --delimiter : \
                --preview "bash -c 'line={1}; start=\$((line > 20 ? line - 20 : 1)); bat --style=numbers --color=always --line-range \$start: --highlight-line {1} \"$target_file\"'" \
                --bind "enter:become(nvim '$target_file' +{1} -c \"normal! zz\")"
        else
            fzf $common_opts \
                --bind "start:reload:rg --color=always --line-number --no-heading --smart-case '' || true" \
                --bind "change:reload:rg --color=always --line-number --no-heading --smart-case {q} || true" \
                --delimiter : \
                --preview 'test -n "{1}" && bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || echo "Type to search files..."' \
                --bind 'enter:become(nvim {1} +{2} -c "normal! zz")'
        end
    else if test "$search_type" = file
        fd --type f --hidden --exclude .git | fzf $common_opts \
            --preview 'bat --style=numbers --color=always {}' \
            --bind 'enter:become(nvim {})'
    else if test "$search_type" = tldr
        tldr --list | fzf $common_opts \
            --preview 'tldr {} --color' \
            --bind 'enter:become(tldr {})'
    else if test "$search_type" = cht
        set -l topic (curl -s cht.sh/:list | fzf $common_opts \
            --preview "curl -s 'cht.sh/{}?style=rrt'")
        stty sane

        if test -n "$topic"
            # Try to get the list of sheets for this topic
            set -l sheets (curl -s "cht.sh/$topic/:list")

            # If there are sheets available, let user choose one
            if test -n "$sheets"
                set -l sheet (printf "%s\n" $sheets | fzf $common_opts \
                    --preview "curl -s 'cht.sh/$topic/{}?style=rrt'")
                stty sane

                if test -n "$sheet"
                    curl -s "cht.sh/$topic/$sheet?style=rrt"
                else
                    curl -s "cht.sh/$topic?style=rrt"
                end
            else
                # No sheets, just show the topic directly
                curl -s "cht.sh/$topic?style=rrt"
            end
        end
    else if test "$search_type" = make
        make -pRrq 2>/dev/null | awk -F: '/^[a-zA-Z0-9][^$#\/\\t=]*:([^=]|$)/ {split($1,a," "); print a[1]}' | sort -u | grep -v '^Makefile$' | fzf $common_opts \
            --preview "awk '/^{}[[:space:]]*:/{found=1} found{print; if(/^[^\\t]/ && NR>1 && !/^{}[[:space:]]*:/) exit}' Makefile | bat --style=plain --language=make --color=always" \
            --bind 'enter:become(make {})'
    else if test "$search_type" = journal
        journalctl --field SYSLOG_IDENTIFIER 2>/dev/null | sort -f | fzf $common_opts \
            --preview "journalctl -b --no-pager -o short-iso -n 50 SYSLOG_IDENTIFIER='{}' 2>/dev/null" \
            --bind 'enter:become(journalctl -f SYSLOG_IDENTIFIER='"'"'{}'"'"')'
    else if test "$search_type" = ps
        ps aux | fzf $common_opts \
            --header-lines=1 \
            --preview 'echo "Process Details:"; echo ""; ps -p {2} -o pid,ppid,user,%cpu,%mem,vsz,rss,tty,stat,start,time,command | tail -n +2; echo ""; echo "Open Files:"; lsof -p {2} 2>/dev/null | head -20' \
            --bind 'enter:become(kill -9 {2})'
    else
        echo "Unknown search type: $search_type"
        echo ""
        echo "Available search types:"
        echo "  grep    - Search file contents with ripgrep (default)"
        echo "  file    - Browse and select files"
        echo "  man     - Search man pages"
        echo "  tldr    - Browse tldr pages"
        echo "  cht     - Browse cht.sh cheat sheets"
        echo "  make    - List and run Makefile targets"
        echo "  journal - Browse systemd journal logs"
        echo "  ps      - Browse running processes"
        return 0
    end

    return 0
end
