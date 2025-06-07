function cht
    set topic (curl -s cht.sh/:list | fzf)
    stty sane

    if test -z "$topic"
        exit 0
    end

    set sheet (curl -s cht.sh/$topic/:list | fzf)

    if test -z "$sheet"
        curl -s "cht.sh/$topic?style=rrt" | less -R
        exit 0
    end

    curl -s "cht.sh/$topic/$sheet?style=rrt" | less -R
end
