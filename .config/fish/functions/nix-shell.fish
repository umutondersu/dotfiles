function nix-shell
    # Check if --run, --command, or -c is already in the arguments
    set -l has_command false
    for arg in $argv
        switch $arg
            case --run --command -c
                set has_command true
                break
        end
    end

    if $has_command
        command nix-shell $argv
    else
        # Stash nix-shell's PATH before fish overwrites it, then restore nix-store
        # entries at the front after fish initialises.
        command nix-shell $argv --run \
            'NIX_SHELL_PATH="$PATH" exec fish -C \
                "set -x PATH (string split : -- \$NIX_SHELL_PATH); true"'
    end
end
