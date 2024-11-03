function dctemplates
    curl -s "https://containers.dev/templates" | grep -o 'ghcr.io/[^<]*' | sort | uniq
end
