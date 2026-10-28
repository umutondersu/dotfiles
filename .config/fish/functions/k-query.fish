function k-query
    set -l dir (test -n "$argv[1]"; and echo "$argv[1]"; or echo ".")
    kubectl kustomize $dir | yq 'select(.kind == "Application")' -o=json | ijq
end
