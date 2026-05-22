function ls
    if test (count $argv) -eq 1 -a -f "$argv[1]"
        cat $argv[1]
    else if type -q lsd
        lsd $argv
    else
        command ls $argv
    end
end
