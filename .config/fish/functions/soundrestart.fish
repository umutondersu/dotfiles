function soundrestart --wraps='systemctl --user restart wireplumber pipewire pipewire-pulse' --description 'alias soundrestart=systemctl --user restart wireplumber pipewire pipewire-pulse'
  systemctl --user restart wireplumber pipewire pipewire-pulse $argv
        
end
