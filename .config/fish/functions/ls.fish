function ls
    if type -q lsd
        lsd $argv
    else
        command ls $argv
    end
end
