function avante --wraps='nvim . -c "lua vim.defer_fn(function()require(\\"avante.api\\").zen_mode()end, 100)"' --description 'alias avante=nvim . -c "lua vim.defer_fn(function()require(\\"avante.api\\").zen_mode()end, 100)"'
  nvim . -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)" $argv
        
end
