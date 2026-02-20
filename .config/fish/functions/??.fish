function ??
    # URL-encode the search query
    set -l query (string join ' ' $argv | string replace -a ' ' '+' | string replace -a '&' '%26' | string replace -a '=' '%3D' | string replace -a '?' '%3F' | string replace -a '#' '%23')
    
    # Open w3m with DuckDuckGo search
    w3m "https://duckduckgo.com/html/?q=$query"
end
