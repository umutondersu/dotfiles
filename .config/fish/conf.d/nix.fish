if test -n "$NIX_STORE" || string match -q "/nix/store/*" $PATH
    set -gx IN_NIX_SHELL impure
end
