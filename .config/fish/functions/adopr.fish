function adopr --description 'Output changes for an Azure DevOps PR using a PAT'
    if test "$argv[1]" = "--help"; or test "$argv[1]" = "-h"
        echo "Usage: adopr [--plain] [PR_ID]"
        echo ""
        echo "Output changes for an Azure DevOps PR."
        echo ""
        echo "Options:"
        echo "  -p, --plain    Output raw git log instead of a formatted diff"
        echo ""
        echo "  No arguments   Open an fzf selector to choose an active PR"
        echo "  PR_ID          Show the diff for a specific PR"
        echo "  -h, --help     Show this help message"
        echo ""
        echo "Environment:"
        echo "  AZURE_DEVOPS_EXT_PAT    Azure DevOps Personal Access Token (required)"
        return 0
    end

    set -l plain 0
    set -l pr_id ""
    for arg in $argv
        if test "$arg" = "--plain"; or test "$arg" = "-p"
            set plain 1
        else
            set pr_id $arg
        end
    end

    # Resolve git path once so subshells (fzf preview) work in Nix environments
    set -l git_cmd (command -s git)
    if test -z "$git_cmd"
        echo "Error: 'git' is required but not found."
        return 1
    end

    # Extract org, project, and repo from git remote
    set -l remote_url ($git_cmd remote get-url origin 2>/dev/null)
    if test $status -ne 0
        echo "Error: Not in a git repository or 'origin' remote not set."
        return 1
    end

    set -l org ""
    set -l proj ""
    set -l repo ""

    # Parse standard HTTPS (dev.azure.com)
    if set matches (string match -r "dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/\n]+)" $remote_url)
        set org $matches[2]
        set proj $matches[3]
        set repo $matches[4]
    # Parse SSH (ssh.dev.azure.com:v3)
    else if set matches (string match -r "ssh\.dev\.azure\.com:v3/([^/]+)/([^/]+)/([^/\n]+)" $remote_url)
        set org $matches[2]
        set proj $matches[3]
        set repo $matches[4]
    # Parse legacy HTTPS (visualstudio.com)
    else if set matches (string match -r "([^/]+)\.visualstudio\.com/([^/]+)/_git/([^/\n]+)" $remote_url)
        set org $matches[2]
        set proj $matches[3]
        set repo $matches[4]
    else
        echo "Error: Could not parse Azure DevOps URL from origin: $remote_url"
        return 1
    end

    set repo (string replace -r '\.git$' '' $repo)

    # If no PR ID was provided, trigger the fzf selector
    if test -z "$pr_id"
        if test -z "$AZURE_DEVOPS_EXT_PAT"
            echo "Error: AZURE_DEVOPS_EXT_PAT environment variable is not set."
            return 1
        end
        if not command -v jq > /dev/null
            echo "Error: 'jq' is required to parse the Azure DevOps API response."
            return 1
        end
        if not command -v fzf > /dev/null
            echo "Error: 'fzf' is required for the interactive menu."
            return 1
        end

        echo "Fetching open pull requests for $repo..."

        # Query the ADO REST API using Basic Auth
        set -l api_url "https://dev.azure.com/$org/$proj/_apis/git/repositories/$repo/pullrequests?searchCriteria.status=active&api-version=7.1"
        set -l api_response (curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$api_url")

        # Check if there are any PRs before trying to open fzf
        set -l pr_count (echo $api_response | jq -r '.value | length')
        if test -z "$pr_count" -o "$pr_count" = "0" -o "$pr_count" = "null"
            echo "No active PRs found, or API request failed (check if your PAT has 'Code: Read' permissions)."
            return 1
        end

        # Define the fzf preview command with the resolved git path
        set -l fzf_preview "sh -c '$git_cmd rev-parse --verify refs/pr/{1} >/dev/null 2>&1 || $git_cmd fetch origin pull/{1}/merge:refs/pr/{1} -f >/dev/null 2>&1; pr_desc=\$(curl -s -u \":\$AZURE_DEVOPS_EXT_PAT\" \"https://dev.azure.com/$org/$proj/_apis/git/repositories/$repo/pullrequests/{1}?api-version=7.1\"); title=\$(echo \$pr_desc | jq -r \".title // empty\"); desc=\$(echo \$pr_desc | jq -r \".description // empty\"); if [ -n \"\$title\" ]; then echo \"PR #{1}: \$title\"; echo \"\"; if [ -n \"\$desc\" ]; then echo \"\$desc\"; echo \"\"; fi; echo \"---\"; echo \"\"; fi; $git_cmd log --oneline --decorate --graph --color=always refs/pr/{1}^1~3..refs/pr/{1}^2'"

        # Format the list and open fzf; jq outputs tab-separated PR ID and title
        set pr_id (echo $api_response | \
                            jq -r '.value[] | "\(.pullRequestId)\t\(.title)"' | \
                            fzf --prompt="Select PR to diff > " \
                                --layout=reverse \
                                --preview=$fzf_preview \
                                --preview-window="right:60%:wrap" | \
                            awk -F'\t' '{print $1}')

        if test -z "$pr_id"
            echo "Aborted: No PR selected."
            return 0
        end
    end

    # Fetch PR details from API to get title and description
    if test -n "$AZURE_DEVOPS_EXT_PAT"
        set -l pr_url "https://dev.azure.com/$org/$proj/_apis/git/repositories/$repo/pullrequests/$pr_id?api-version=7.1"
        set -l pr_details (curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$pr_url")
        set -l pr_title (echo $pr_details | jq -r '.title // empty')
        set -l pr_description (echo $pr_details | jq -r '.description // empty')

        if test -n "$pr_title"
            echo ""
            echo "PR #$pr_id: $pr_title"
            if test -n "$pr_description"
                echo "$pr_description"
            end
            echo ""
            echo "---"
            echo ""
        end
    end

    echo "Ensuring PR $pr_id is fully up to date..."
    $git_cmd fetch origin pull/$pr_id/merge:refs/pr/$pr_id -f

    if test $status -ne 0
        echo "Failed to fetch PR $pr_id. Does it exist?"
        return 1
    end

    if test "$plain" = "1"
        $git_cmd log -p refs/pr/$pr_id^1..refs/pr/$pr_id^2
    else if command -v delta > /dev/null 2>&1
        $git_cmd diff --color=always refs/pr/$pr_id^1..refs/pr/$pr_id^2 | delta
    else
        $git_cmd diff --color=always refs/pr/$pr_id^1..refs/pr/$pr_id^2 | less -R
    end
end
