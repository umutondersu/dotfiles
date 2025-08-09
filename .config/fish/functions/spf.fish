function spf --description 'wrapper for spf'
    if test (count $argv) -eq 0
        command spf $PWD
    else
        command spf $argv
    end
end
