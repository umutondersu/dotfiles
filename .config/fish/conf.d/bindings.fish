function bind-both
    bind $argv
    bind -M insert $argv
end

bind-both \cg tv
bind -M insert \ca forward-char
bind-both \cw y
