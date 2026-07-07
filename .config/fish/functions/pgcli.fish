function pgcli --description 'Wrap pgcli, auto-using $DATABASE_URL when set'
    if not command -q pgcli
        echo "warning: pgcli is not installed" >&2
        return 1
    end

    if set -q DATABASE_URL; and test -n "$DATABASE_URL"; and test (count $argv) -eq 0
        command pgcli $DATABASE_URL
    else
        command pgcli $argv
    end
end
