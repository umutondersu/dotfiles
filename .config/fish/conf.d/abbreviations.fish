if type -q rip
    abbr --add --set-cursor rs "rip search deezer track '%'"
    abbr --add --set-cursor ra "rip search deezer album '%'"
    abbr --add --set-cursor ru "rip url '%'"
end

if type -q devbox
    abbr --add db devbox
    abbr --add ds devbox search
    abbr --add dS devbox shell
    abbr --add dgc "devbox global run -- nix store gc --extra-experimental-features nix-command"

    abbr --add dg devbox global
    abbr --add da devbox global add
    abbr --add dgu devbox global update
    abbr --add dr devbox global rm
    abbr --add dl devbox global list

    abbr --add dA devbox add
    abbr --add dU devbox update
    abbr --add dR devbox rm
    abbr --add dL devbox list
end

if type -q nix
    abbr --add --set-cursor nr "nix run nixpkgs#%"
    abbr --add --set-cursor ns "nix shell nixpkgs#%"
    abbr --add gob "nix shell nixpkgs#go nixpkgs#go-blueprint -c go-blueprint create --advanced"
    abbr --add --set-cursor np --position anywhere "nixpkgs#%"
    abbr --add ngc nix store gc
    abbr --add --position anywhere nf nixfind
    if type -q nix-search
        abbr --add nS nix-search
    else
        abbr --add nS nix search
    end
end

if type -q nvim
    abbr --add v nvim
    abbr --add V --position anywhere "&& nvim"
    abbr --add nvim-min 'NVIM_APPNAME="nvim-min" nvim'
    abbr --add vm 'NVIM_APPNAME="nvim-min" nvim'
end

if type -q opencode
    abbr --add o opencode
end

if type -q spf
    abbr --add s spf
end

if type -q lazygit
    abbr --add lg lazygit
    abbr --add G lazygit
end

if type -q bunx
    abbr --add shad bunx --bun shadcn@latest
end

if type -q lsd
    abbr --add lT ls --tree --depth 2
    abbr --add lt 'ls -I node_modules -I dist -I build -I target -I out -I tmp -I __pycache__ --tree --depth 2'
end

if type -q yt-dlp
    function _abbr_yt
        set clip ""
        if type -q wl-paste
            set clip (wl-paste 2>/dev/null)
        else if type -q xclip
            set clip (xclip -selection clipboard -o 2>/dev/null)
        end
        echo "yt-dlp -x --audio-format opus --audio-quality 0 \"$clip\""
    end
    abbr --add yt --function _abbr_yt
end

if type -q wl-copy
    abbr --add Y --position anywhere "| wl-copy"
    abbr --add P "wl-paste >"
else if type -q xclip
    abbr --add Y --position anywhere "| xclip -selection clipboard"
    abbr --add P "xclip -selection clipboard -o >"
end

if type -q konsave
    abbr --add --set-cursor=@ ks 'konsave -e my-setup -f && mv ./my-setup.knsv "@/my-setup-$(date +%Y%m%d).knsv"'
end

if type -q apt-get
    if type -q devbox
        abbr --add update 'sudo apt update && sudo apt upgrade -y && devbox global update && flatpak update -y'
    else
        abbr --add update 'sudo apt update && sudo apt upgrade -y && flatpak update -y'
    end
end

abbr --add l ls
abbr --add ll ls -lg
abbr --add la ls -A
abbr --add lla ls -lgA
abbr --add lS ls -lgSA

abbr c --add cd
abbr g --add git
abbr gs --add git status -s
abbr gi --add git update-index --skip-worktree

abbr --add claer clear
abbr --add clr clear

abbr --add --set-cursor tc tar -czf file.tar.gz ./%
abbr --add --set-cursor tC tar -czf file.tar.gz --drectory .%
abbr --add --set-cursor tx tar -xzf %.tar.gz
abbr --add --set-cursor tl tar -tf %.tar.gz

abbr --add odlog journalctl --user-unit=onedrive -f
abbr --add python python3
abbr --add fk sudo kill -9
abbr --add B --position anywhere ">/dev/null 2>&1 &"
abbr --add src source
abbr --add bios "systemctl reboot --firmware-setup"
