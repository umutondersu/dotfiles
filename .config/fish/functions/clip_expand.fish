# clip_expand TEMPLATE
#
# Helper for abbreviation --function callbacks.
# Reads the clipboard and substitutes the placeholder `%` in TEMPLATE with
# the clipboard content (quoted).  If no `%` is present the clipboard value
# is appended at the end.
#
# Usage inside an abbr function:
#   function _abbr_foo
#   clip_expand "some-cmd --flag '%'"
#   end
#   abbr --add foo --function _abbr_foo
#
function clip_expand --argument-names template
    set -l clip ""
    if type -q wl-paste
        set clip (wl-paste 2>/dev/null)
    else if type -q xclip
        set clip (xclip -selection clipboard -o 2>/dev/null)
    end

    if string match -q '*%*' -- $template
        echo (string replace '%' $clip -- $template)
    else
        echo "$template $clip"
    end
end
