function ?
    # Parse optional model parameter (format: --model <model>, -m <model>, or -M for claude-sonnet)
    set -l model ""
    set -l query_args

    set -l i 1
    while test $i -le (count $argv)
        if test "$argv[$i]" = -M
            set model opencode/glm-5-free
        else if test "$argv[$i]" = --model -o "$argv[$i]" = -m
            set i (math $i + 1)
            if test $i -le (count $argv)
                set model $argv[$i]
            end
        else
            set -a query_args $argv[$i]
        end
        set i (math $i + 1)
    end

    # Run opencode and pipe through glow, hide build message
    if test -n "$model"
        opencode run --model $model $query_args 2>/dev/null | glow -
    else
        opencode run $query_args 2>/dev/null | glow -
    end

    # Get the most recent session ID (skip header and separator, get first data line)
    set -l session_id (opencode session list 2>/dev/null | sed -n '3p' | awk '{print $1}')

    if test -n "$session_id"
        opencode session delete $session_id >/dev/null 2>&1
    end
end
