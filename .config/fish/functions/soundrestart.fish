function soundrestart
    set -l discord_was_running false
    set -l easyeffects_was_running false
    echo "Restarting sound system..."

    # Find and kill EasyEffects process
    if set -l pid (pgrep easyeffects)
        set easyeffects_was_running true
        kill $pid
        sleep 2 # Wait for EasyEffects to fully close
        echo "EasyEffects stopped"
    end

    # Find and kill Discord process
    if set -l pid (pgrep -i discord)
        set discord_was_running true
        kill $pid
        sleep 2 # Wait for Discord to fully close
        echo "Discord stopped"
    end

    # Restart sound system services
    echo "Restarting PipeWire services..."
    if not systemctl --user restart wireplumber pipewire pipewire-pulse
        echo "Error: Failed to restart sound services"
        return 1
    end

    # Wait longer for services to stabilize
    echo "Waiting for services to stabilize..."
    sleep 5

    # Check if services are running
    if systemctl --user is-active pipewire >/dev/null
        echo "Sound services restarted successfully"
        if $easyeffects_was_running
            echo "Starting EasyEffects..."
            flatpak run com.github.wwmm.easyeffects --gapplication-service --start-minimized >/dev/null 2>&1 &
            disown
        end
        if $discord_was_running
            echo "Starting Discord..."
            flatpak run com.discordapp.Discord >/dev/null 2>&1 &
            disown
        end
    else
        echo "Error: PipeWire service failed to start"
        return 1
    end
end
