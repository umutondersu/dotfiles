function sourcefish --description 'Source all .fish files in ~/.config/fish recursively'
    for file in (find ~/.config/fish -type f -name '*.fish')
        source $file
    end
end
