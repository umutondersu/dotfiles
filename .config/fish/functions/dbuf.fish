function dbuf -d "Update all global devbox flakes by removing and re-adding them"
    set -l flakes (devbox global list | rg -o 'github:[^ "]*')

    if test (count $flakes) -eq 0
        echo "No flakes found in devbox global packages."
        return 0
    end

    echo "Updating flakes:"
    for flake in $flakes
        echo "  $flake"
    end
    echo ""

    if set -q _flag_dry_run
        echo "[DRY RUN] No changes made."
        return 0
    end

    echo "Removing flakes..."
    devbox global rm $flakes
    or return 1

    echo "Re-adding flakes..."
    devbox global add $flakes
    or return 1

    echo "Done. All flakes updated."
end
