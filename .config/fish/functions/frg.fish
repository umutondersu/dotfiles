function frg
    fzf --ansi \
        --disabled \
        --bind "change:reload:rg --color=always --line-number --no-heading --smart-case {q} || true" \
        --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window 'right:50%' \
        --bind 'enter:become(nvim {1} +{2})'
end
