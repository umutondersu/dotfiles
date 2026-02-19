function bind-both
    bind $argv
    bind -M insert $argv
end

bind-both \cg fz
bind -M insert \ca forward-char
