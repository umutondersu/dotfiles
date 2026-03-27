function ffm --description 'Fuzzy-finder TUI for managing Flatpak packages'

    # --- fzf base args ---
    set fzf_args \
        --multi \
        --ansi \
        --preview-window down:65%:wrap \
        --bind alt-p:toggle-preview \
        --bind alt-d:preview-half-page-down,alt-u:preview-half-page-up \
        --bind alt-k:preview-up,alt-j:preview-down \
        --color pointer:green,marker:green

    # --- parse args ---
    set mode install
    set install_flag --user
    set query ''

    switch "$argv[1]"
        case -R --remove
            set mode remove
            set query "$argv[2]"
        case -l --list
            set mode list
            set query "$argv[2]"
        case -U --update
            set mode update
        case --system
            set install_flag --system
            set query "$argv[2]"
        case -h --help
            echo 'ffm (Fuzzy Flatpak Manager)'
            echo 'Usage: ffm [OPTIONS] [query]'
            echo ''
            echo 'Options:'
            echo '  -R, --remove     Search installed Flatpaks to remove'
            echo '  -l, --list       List/search installed Flatpaks'
            echo '  -U, --update     Update installed Flatpaks'
            echo '      --system     Install to system instead of user'
            echo '  -h, --help       Print this help screen'
            return 0
        case '-*'
            echo "Unknown option: $argv[1]"
            ffm --help
            return 1
        case '*'
            set query "$argv[1]"
    end

    # --- modes ---
    switch $mode

        case install
            set results (flatpak search --columns=name,application,version,branch,remotes,description '' 2>/dev/null)
            if test -z "$results"
                echo 'No flatpak remotes available or search failed.'
                return 1
            end
            set chosen (printf "%s\n" $results | fzf $fzf_args \
                --delimiter='\t' \
                --with-nth=1,3,6 \
                --preview='flatpak search --columns=name,application,version,branch,remotes,description {2} 2>/dev/null' \
                --preview-label='alt-p: toggle preview, alt-j/k: scroll, tab: multi-select' \
                --header="Flatpak packages  [$install_flag]  (Tab=multi-select, Enter=install)" \
                --layout=reverse \
                --query "$query")
            if test -z "$chosen"
                return 0
            end
            set app_ids
            set remotes
            for line in $chosen
                set app_id (printf "%s" $line | awk -F'\t' '{print $2}')
                set remote (printf "%s" $line | awk -F'\t' '{print $5}')
                if test -n "$app_id"
                    set -a app_ids $app_id
                    set -a remotes $remote
                end
            end
            for i in (seq (count $app_ids))
                set remote $remotes[$i]
                set app_id $app_ids[$i]
                if flatpak remotes $install_flag 2>/dev/null | string match -q $remote
                    flatpak install $install_flag $remote $app_id
                else
                    flatpak install $remote $app_id
                end
            end

        case list
            set installed (flatpak list --app --columns=name,application,version,branch,installation 2>/dev/null)
            if test -z "$installed"
                echo 'No Flatpaks installed.'
                return 0
            end
            printf "%s\n" $installed | fzf $fzf_args \
                --delimiter='\t' \
                --with-nth=1,3,5 \
                --preview='flatpak info {2} 2>/dev/null' \
                --preview-label='alt-p: toggle preview, alt-j/k: scroll' \
                --header='Installed Flatpaks' \
                --layout=reverse \
                --query "$query"

        case remove
            set installed (flatpak list --app --columns=name,application,version,branch,installation 2>/dev/null)
            if test -z "$installed"
                echo 'No Flatpaks installed.'
                return 0
            end
            set chosen (printf "%s\n" $installed | fzf $fzf_args \
                --delimiter='\t' \
                --with-nth=1,3,5 \
                --preview='flatpak info {2} 2>/dev/null' \
                --preview-label='alt-p: toggle preview, alt-j/k: scroll, tab: multi-select' \
                --header='Select Flatpaks to REMOVE  (Tab=multi-select, Enter=remove)' \
                --layout=reverse \
                --query "$query")
            if test -z "$chosen"
                return 0
            end
            set app_ids
            for line in $chosen
                set app_id (printf "%s" $line | awk -F'\t' '{print $2}')
                if test -n "$app_id"
                    set -a app_ids $app_id
                end
            end
            if test (count $app_ids) -gt 0
                flatpak uninstall $app_ids
            end

        case update
            set updates (flatpak remote-ls --updates --app --columns=name,application,version,branch,installation 2>/dev/null)
            if test -z "$updates"
                echo 'All Flatpaks are up to date.'
                return 0
            end
            set chosen (printf "%s\n" $updates | fzf $fzf_args \
                --delimiter='\t' \
                --with-nth=1,3,5 \
                --preview='flatpak info {2} 2>/dev/null' \
                --preview-label='alt-p: toggle preview, alt-j/k: scroll, tab: multi-select' \
                --header='Flatpaks with updates  (Tab=multi-select, Enter=update selected, Esc=update all)' \
                --layout=reverse \
                --bind 'esc:execute(flatpak update)+abort')
            if test -z "$chosen"
                return 0
            end
            set app_ids
            for line in $chosen
                set app_id (printf "%s" $line | awk -F'\t' '{print $2}')
                if test -n "$app_id"
                    set -a app_ids $app_id
                end
            end
            if test (count $app_ids) -gt 0
                flatpak update $app_ids
            end

    end

end
