function onedrivelog --wraps='journalctl --user-unit=onedrive -f' --description 'alias onedrivelog=journalctl --user-unit=onedrive -f'
  journalctl --user-unit=onedrive -f $argv
        
end
