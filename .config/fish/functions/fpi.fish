function fpi
    if test (count $argv) -eq 0
        echo "Usage: fpi [--system] <search query>"
        return 1
    end

    set -l install_flag --user
    set -l query_args

    for arg in $argv
        if test "$arg" = --system
            set install_flag --system
        else
            set -a query_args $arg
        end
    end

    if test (count $query_args) -eq 0
        echo "Usage: fpi [--system] <search query>"
        return 1
    end

    set -l query (string join ' ' $query_args)
    set -l results (flatpak search --columns=name,application,version,branch,remotes,description $query 2>/dev/null)

    if test -z "$results"
        echo "No results found for: $query"
        return 1
    end

    set -l chosen (printf "%s\n" $results | fzf \
        --ansi \
        --layout=reverse \
        --header="Flatpak search: $query  [$install_flag]  (Tab=multi-select, Enter=install)" \
        --delimiter='\t' \
        --with-nth=1,2,3,6 \
        --preview='flatpak search --columns=name,application,version,branch,remotes,description {2} 2>/dev/null | head -5' \
        --preview-window='down:5:wrap' \
        --multi)

    if test -z "$chosen"
        return 0
    end

    set -l app_ids
    set -l remotes
    for line in $chosen
        set -l app_id (printf "%s" $line | awk -F'\t' '{print $2}')
        set -l remote (printf "%s" $line | awk -F'\t' '{print $5}')
        if test -n "$app_id"
            set -a app_ids $app_id
            set -a remotes $remote
        end
    end

    if test (count $app_ids) -eq 0
        return 0
    end

    # Install each app with its corresponding remote
    for i in (seq (count $app_ids))
        set -l remote $remotes[$i]
        set -l app_id $app_ids[$i]
        # Only pass the scope flag if the remote is registered in that installation
        if flatpak remotes $install_flag 2>/dev/null | string match -q $remote
            echo "Installing: $app_id from $remote ($install_flag)"
            flatpak install $install_flag $remote $app_id
        else
            echo "Installing: $app_id from $remote (remote not in $install_flag, letting flatpak resolve)"
            flatpak install $remote $app_id
        end
    end
end
