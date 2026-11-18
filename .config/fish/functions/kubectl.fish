function kubectl --description 'Wrap kubectl to intercept krew calls'
    if not command -q kubectl
        return 127
    end

    if test (count $argv) -gt 0; and test "$argv[1]" = "krew"
        command krew $argv[2..-1]
    else
        command kubectl $argv
    end
end
