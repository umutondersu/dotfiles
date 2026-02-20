#!/bin/sh

# Source:https://rkta.de/anti-cf.html
# Circumvent Clownfare with curl

# Put this file in one of the configured cgi-bin directories of w3m and make
# it executable.
# Add the two next lines your ~/.w3m/siteconf omitting the # at the beginning
#url m!^https?://stackoverflow.com/!
#substitute_url "file:///cgi-bin/anti-cf.cgi?"
#url m!^https?://.*stackexchange.com/!
#substitute_url "file:///cgi-bin/anti-cf.cgi?"

printf "%s\n\n" "Content-Type: text/html"

# If W3M_CURRENT_LINK is set, use it to extract the domain
if [ "$W3M_CURRENT_LINK" != "" ]; then
    url=$(echo "$W3M_CURRENT_LINK" | sed 's@\(http.\{0,1\}://[^/]*\)/.*@\1@')
    curl -L "$url/$QUERY_STRING"
else
    # Fallback: determine the site from the path
    # The QUERY_STRING contains the path after the domain
    case "$QUERY_STRING" in
        questions/*|tagged/*|users/*|search*)
            # Stack Overflow paths
            curl -L "https://stackoverflow.com/$QUERY_STRING"
            ;;
        *stackexchange.com*)
            # Full Stack Exchange URL in query string
            curl -L "https://$QUERY_STRING"
            ;;
        *)
            # Default: assume GitHub
            curl -L "https://github.com/$QUERY_STRING"
            ;;
    esac
fi
