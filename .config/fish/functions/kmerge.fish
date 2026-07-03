function kmerge --description "Merge kubeconfigs from a directory (default: ~/kubeconfig) or a single file into ~/.kube/config"
    if not command -q kubectl
        echo "Error: kubectl is not installed." >&2
        return 1
    end

    # Ensure ~/.kube exists
    mkdir -p $HOME/.kube

    set -l new_configs

    if set -q argv[1]
        if test -f "$argv[1]"
            # Single kubeconfig file passed directly
            echo "Merging kubeconfig from file $argv[1]..."
            set new_configs $argv[1]
        else if test -d "$argv[1]"
            # Directory passed — find YAML kubeconfig files inside it
            echo "Merging kubeconfigs from directory $argv[1]..."
            set new_configs (find "$argv[1]" -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" -o -name "config" \) | string join ':')
        else
            echo "Error: '$argv[1]' is not a file or directory." >&2
            return 1
        end
    else
        # Default: use ~/kubeconfig directory
        set -l kube_dir $HOME/kubeconfig
        if not test -d "$kube_dir"
            echo "Error: Default directory '$kube_dir' does not exist." >&2
            return 1
        end
        echo "Merging kubeconfigs from $kube_dir..."
        set new_configs (find "$kube_dir" -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" -o -name "config" \) | string join ':')
    end

    # If no files were found, exit early (before touching the backup)
    if test -z "$new_configs"
        echo "No config files found. Nothing to merge."
        return 0
    end

    # Back up existing config with a timestamp
    if test -f $HOME/.kube/config
        cp $HOME/.kube/config $HOME/.kube/config.bak.(date +%Y%m%d%H%M%S)
    end

    # Flatten into a temp file, then atomically replace only on success
    set -l tmp (mktemp $HOME/.kube/config.tmp.XXXXXX)
    if env KUBECONFIG=$HOME/.kube/config:$new_configs kubectl config view --flatten >$tmp
        mv $tmp $HOME/.kube/config
        chmod 600 $HOME/.kube/config
        echo "Done! Your contexts are updated."
    else
        echo "Error: merge failed. Config unchanged." >&2
        rm -f $tmp
        return 1
    end
end
