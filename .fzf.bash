# Setup fzf
# ---------
if [[ ! "$PATH" == */home/qorcialwolf/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/qorcialwolf/.fzf/bin"
fi

eval "$(fzf --bash)"
