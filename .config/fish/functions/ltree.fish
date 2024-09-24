function ltree --wraps='lsd -tree' --wraps='lsd --tree' --wraps='lsd --tree --depth 2' --description 'alias ltree=lsd --tree --depth 2'
  lsd --tree --depth 2 $argv
        
end
