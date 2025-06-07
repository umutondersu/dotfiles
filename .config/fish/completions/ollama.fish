function __ollama_list
    set -l query (string join ' ' $argv)
    ollama list $query | awk 'NR > 1 { gsub(/:latest$/, "", $1); print $1 }'
end

# Complete subcommands for ollama with descriptions
complete -c ollama -n __fish_use_subcommand -f -a serve -d "Start ollama"
complete -c ollama -n __fish_use_subcommand -f -a create -d "Create a model from a Modelfile"
complete -c ollama -n __fish_use_subcommand -f -a show -d "Show information for a model"
complete -c ollama -n __fish_use_subcommand -f -a run -d "Run a model"
complete -c ollama -n __fish_use_subcommand -f -a pull -d "Pull a model from a registry"
complete -c ollama -n __fish_use_subcommand -f -a push -d "Push a model to a registry"
complete -c ollama -n __fish_use_subcommand -f -a "list ls" -d "List models"
complete -c ollama -n __fish_use_subcommand -f -a ps -d "List running models"
complete -c ollama -n __fish_use_subcommand -f -a cp -d "Copy a model"
complete -c ollama -n __fish_use_subcommand -f -a rm -d "Remove a model"
complete -c ollama -n __fish_use_subcommand -f -a help -d "Help about any command"

# Add --help flag for all subcommands
for subcmd in serve create show run pull push list ls ps cp rm help
    complete -c ollama -n "__fish_seen_subcommand_from $subcmd" -l help -s h -d "Help for $subcmd"
end

# Complete options for ollama create command
complete -c ollama -n '__fish_seen_subcommand_from create' -l file -s f -d 'Name of the Modelfile (default "Modelfile")'
complete -c ollama -n '__fish_seen_subcommand_from create' -l quantize -s q -d 'Quantize model to this level (e.g. q4_0)'

# Complete options for ollama show command
complete -c ollama -n '__fish_seen_subcommand_from show' -l license -d 'Show license of a model'
complete -c ollama -n '__fish_seen_subcommand_from show' -l modelfile -d 'Show Modelfile of a model'
complete -c ollama -n '__fish_seen_subcommand_from show' -l parameters -d 'Show parameters of a model'
complete -c ollama -n '__fish_seen_subcommand_from show' -l system -d 'Show system message of a model'
complete -c ollama -n '__fish_seen_subcommand_from show' -l template -d 'Show template of a model'

# Complete options for ollama pull command
complete -c ollama -n '__fish_seen_subcommand_from pull' -l insecure -d 'Use an insecure registry'

# Complete options for ollama push command
complete -c ollama -n '__fish_seen_subcommand_from push' -l insecure -d 'Use an insecure registry'

# Complete options for ollama list command
complete -c ollama -n '__fish_seen_subcommand_from list ls' -l help -s h -d 'Help for list'

# Complete options for ollama run command
complete -c ollama -n '__fish_seen_subcommand_from run' -l format -d 'Response format (e.g. json)'
complete -c ollama -n '__fish_seen_subcommand_from run' -l insecure -d 'Use an insecure registry'
complete -c ollama -n '__fish_seen_subcommand_from run' -l keepalive -d 'Duration to keep a model loaded (e.g. 5m)'
complete -c ollama -n '__fish_seen_subcommand_from run' -l nowordwrap -d "Don't wrap words to the next line automatically"
complete -c ollama -n '__fish_seen_subcommand_from run' -l verbose -d 'Show timings for response'

# Complete the model names for ollama show, push, rm, run, and cp commands
complete -c ollama -n '__fish_seen_subcommand_from run' -f -a '(__ollama_list (commandline -ct))'
complete -c ollama -n '__fish_seen_subcommand_from show' -f -a '(__ollama_list (commandline -ct))'
complete -c ollama -n '__fish_seen_subcommand_from push' -f -a '(__ollama_list (commandline -ct))'
complete -c ollama -n '__fish_seen_subcommand_from rm' -f -a '(__ollama_list (commandline -ct))'
complete -c ollama -n '__fish_seen_subcommand_from cp' -f -a '(__ollama_list (commandline -ct))'
