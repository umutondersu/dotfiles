#config alias
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

#fd
alias fd='fdfind'

#python
alias py='python3'
alias python='python3'

# tmux kill all sessions alias
alias skill='pkill -f tmux' 

# vi and vim aliases
alias vi='nvim'
alias vim='nvim'
