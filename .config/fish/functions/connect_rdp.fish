function connect_rdp
    xfreerdp -grab-keyboard /v:192.168.122.29 /u:qorcialwolf /p:susam123 /scale:180 /d: /dynamic-resolution +gfx-progressive /sound:sys:alsa /w:1920 /h:1080 >/dev/null 2>&1 &
end
