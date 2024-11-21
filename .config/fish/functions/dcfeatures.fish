function dcfeatures
    curl -s "https://containers.dev/features" | grep -o 'ghcr.io/[^<]*' | sort | uniq
end
