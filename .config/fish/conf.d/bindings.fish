function bind-both
    bind $argv
    bind -M insert $argv
end

bind-both \cg livegrep
bind -M insert \ca forward-char
bind-both \cf spf
