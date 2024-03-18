function cat
    if type -q bat
        bat $argv
    else
        echo "installing bat"
        wget -qO- https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-musl_0.24.0_amd64.deb && sudo dpkg -i bat-musl_0.24.0_amd64.deb
    end
end
