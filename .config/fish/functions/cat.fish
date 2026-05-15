function cat
    if test (count $argv) -eq 1 -a -d "$argv[1]"
        ls $argv[1]
    else if type -q bat
        bat $argv
    else
        command cat $argv
    end
end
