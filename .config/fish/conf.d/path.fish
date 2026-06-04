fish_add_path /usr/bin
fish_add_path ~/.local/bin
fish_add_path ~/bin
fish_add_path ~/go/bin

# macOS: Homebrew (Apple Silicon)
if test (uname) = Darwin
    fish_add_path /opt/homebrew/bin
    fish_add_path /opt/homebrew/sbin
end
