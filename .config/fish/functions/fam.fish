function fam --description 'Fuzzy-finder TUI for managing Arch packages'

    # --- fzf base args ---
    set fzf_args \
        --multi \
        --preview-label-pos=bottom \
        --preview-window down:65%:wrap \
        --bind alt-p:toggle-preview \
        --bind alt-d:preview-half-page-down,alt-u:preview-half-page-up \
        --bind alt-k:preview-up,alt-j:preview-down \
        --color pointer:green,marker:green

    set label_default 'alt-p: toggle description, alt-j/k: scroll, tab: multi-select'

    # --- parse args ---
    set mode official
    set query ''

    switch "$argv[1]"
        case -a --aur
            set mode aur
            set query "$argv[2]"
        case -l --list-installed
            set mode list-installed
            set query "$argv[2]"
        case -la --list-aur-installed
            set mode list-aur-installed
            set query "$argv[2]"
        case -R --remove
            set mode remove
            set query "$argv[2]"
        case -o --orphans
            set mode orphans
        case -U --update
            set mode update
        case -h --help
            echo 'Usage: fpf [OPTIONS] [pkg name]'
            echo ''
            echo 'Searching for a package:'
            echo '  fpf [pkg name]        Search and install from official repo'
            echo '  fpf -a [pkg name]     Search and install from AUR'
            echo ''
            echo 'Options:'
            echo '  -a, --aur                    Search/List and install from AUR with Paru'
            echo '  -l, --list-installed         Search/List installed packages from official repo'
            echo '  -la, --list-aur-installed    Search/List installed packages from AUR'
            echo '  -R, --remove                 Search/List installed packages for removal'
            echo '  -o, --orphans                Search/List orphaned packages for removal'
            echo '  -U, --update                 Show packages with updates available'
            echo '  -h, --help                   Print this help screen'
            return 0
        case '-*'
            echo "Unknown option: $argv[1]"
            fpf --help
            return 1
        case '*'
            set mode official
            set query "$argv[1]"
    end

    # --- modes ---
    switch $mode

        case official
            # Build list: all sync pkgs with descriptions, installed ones marked green *
            set tmp_all /tmp/fpf-all
            set tmp_inst /tmp/fpf-inst
            expac -S '%-30n\t%d' | sort -u >$tmp_all
            expac '%-30n\t%d' | sort -u >$tmp_inst
            # not-installed: in sync but not local
            set tmp_notinst /tmp/fpf-notinst
            comm -23 $tmp_all $tmp_inst >$tmp_notinst
            # installed: mark with green *
            set tmp_marked /tmp/fpf-marked
            comm -12 $tmp_all $tmp_inst | awk -F'\t' '{print $1" \033[32m*\033[0m\t"$2}' >$tmp_marked
            sort $tmp_notinst $tmp_marked >/tmp/fpf-packages
            set pkg_names (cat /tmp/fpf-packages | fzf $fzf_args \
                --ansi \
                --preview 'pacman -Sii {1}' \
                --preview-label=$label_default \
                --query "$query" | awk '{print $1}' | string replace -r '\*$' '')
            if test -n "$pkg_names"
                sudo pacman -S $pkg_names
            end

        case aur
            if not command -q paru
                echo 'Error: paru is not installed.' >&2
                return 1
            end
            set pkg_names (paru -Slq | fzf $fzf_args \
                --preview 'paru -Sii {1} 2>/dev/null || pacman -Sii {1} 2>/dev/null' \
                --preview-label=$label_default \
                --query "$query" \
                --bind 'ctrl-p:preview:curl --silent "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h={1}"' \
                --bind 'ctrl-x:preview:paru -Sii {1} 2>/dev/null || pacman -Sii {1} 2>/dev/null')
            if test -n "$pkg_names"
                paru -S $pkg_names
            end

        case list-installed
            set pkg_names (expac '%-30n\t%d' (pacman -Qnq) | fzf $fzf_args \
                --ansi \
                --preview 'pacman -Qii {1}' \
                --preview-label='Installed (official) — alt-p: toggle, tab: multi-select' \
                --query "$query" | awk '{print $1}')
            if test -n "$pkg_names"
                echo 'Selected package(s):'
                echo $pkg_names
            end

        case list-aur-installed
            set pkg_names (expac '%-30n\t%d' (pacman -Qmq) | fzf $fzf_args \
                --ansi \
                --preview 'pacman -Qii {1}' \
                --preview-label='Installed (AUR) — alt-p: toggle, tab: multi-select' \
                --query "$query" | awk '{print $1}')
            if test -n "$pkg_names"
                echo 'Selected package(s):'
                echo $pkg_names
            end

        case remove
            set pkg_names (expac '%-30n\t%d' (pacman -Qq) | fzf $fzf_args \
                --ansi \
                --preview 'pacman -Qii {1}' \
                --preview-label='Select packages to REMOVE — tab: multi-select' \
                --query "$query" | awk '{print $1}')
            if test -n "$pkg_names"
                sudo pacman -Rns $pkg_names
            end

        case orphans
            set orphan_list (pacman -Qdtq)
            if test -z "$orphan_list"
                echo 'No orphaned packages found.'
                return 0
            end
            set pkg_names (expac '%-30n\t%d' $orphan_list | fzf $fzf_args \
                --ansi \
                --preview 'pacman -Qii {1}' \
                --preview-label='Orphaned packages — tab: multi-select to remove' | awk '{print $1}')
            if test -n "$pkg_names"
                sudo pacman -Rns $pkg_names
            end

        case update
            if command -q paru
                set updates (paru -Qu 2>/dev/null)
            else
                set updates (pacman -Qu 2>/dev/null)
            end
            if test -z "$updates"
                echo 'Everything is up to date.'
                return 0
            end
            set pkg_names (echo $updates | fzf $fzf_args \
                --preview 'pacman -Sii {1} 2>/dev/null || paru -Sii {1} 2>/dev/null' \
                --preview-label='Packages with updates — tab: multi-select to update')
            if test -n "$pkg_names"
                # Extract just package names (first column of "pkg old -> new" output)
                set names (echo $pkg_names | string split ' ' | awk 'NR%4==1')
                if command -q paru
                    paru -S $names
                else
                    sudo pacman -S $names
                end
            end

    end

end
