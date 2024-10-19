function ls
    if type -q lsd
        lsd $argv
    else
        if ! type -q cargo
            echo "Cargo is not installed! install and try again"
            return
        end
        echo "installing lsd"
        cargo install lsd
    end
end
