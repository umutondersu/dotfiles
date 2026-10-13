function adopr --description 'Output changes for an Azure DevOps PR using a PAT'
    if test "$argv[1]" = --help; or test "$argv[1]" = -h
        echo "Usage: adopr [--plain] [--comments] [--no-comments] [--system] [--output [PATH]] [PR_ID]"
        echo ""
        echo "Output changes for an Azure DevOps PR."
        echo ""
        echo "Options:"
        echo "  -p, --plain          Output raw git log instead of a formatted diff"
        echo "  -c, --comments       Show only the review discussion (no diff)"
        echo "  -o, --output [PATH]  Write raw diff to a file (default: <PR_ID>.patch in repo root)"
        echo "  --no-comments        Skip fetching and displaying the review discussion"
        echo "  --system             Include system messages (votes, reviewer changes, ref updates)"
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
    set -l show_comments 1
    set -l show_system 0
    set -l comments_only 0
    set -l output 0
    set -l output_path ""
    set -l pr_id ""
    set -l pr_title ""
    set -l pr_description ""
    set -l pr_status ""
    set -l source_commit ""
    set -l target_commit ""
    set -l merge_commit ""

    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        switch $arg
            case --plain -p
                set plain 1
            case --comments -c
                set comments_only 1
            case --no-comments
                set show_comments 0
            case --system
                set show_system 1
            case -o --output
                set output 1
                set -l next_idx (math $i + 1)
                if test $next_idx -le (count $argv)
                    set -l next $argv[$next_idx]
                    if not string match -q -- '-*' $next
                        set output_path $next
                        set i $next_idx
                    end
                end
            case '*'
                set pr_id $arg
        end
        set i (math $i + 1)
    end

    set -l git_cmd (command -s git)
    if test -z "$git_cmd"
        echo "Error: 'git' is required but not found."
        return 1
    end

    set -l remote_url ($git_cmd remote get-url origin 2>/dev/null)
    if test $status -ne 0
        echo "Error: Not in a git repository or 'origin' remote not set."
        return 1
    end

    set -l org ""
    set -l proj ""
    set -l repo ""

    if set matches (string match -r "dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/\n]+)" $remote_url)
        set org $matches[2]
        set proj $matches[3]
        set repo $matches[4]
    else if set matches (string match -r "ssh\.dev\.azure\.com:v3/([^/]+)/([^/]+)/([^/\n]+)" $remote_url)
        set org $matches[2]
        set proj $matches[3]
        set repo $matches[4]
    else if set matches (string match -r "([^/]+)\.visualstudio\.com/([^/]+)/_git/([^/\n]+)" $remote_url)
        set org $matches[2]
        set proj $matches[3]
        set repo $matches[4]
    else
        echo "Error: Could not parse Azure DevOps URL from origin: $remote_url"
        return 1
    end

    set repo (string replace -r '\.git$' '' $repo)

    # Interactive selector if no PR specified
    if test -z "$pr_id"
        if test -z "$AZURE_DEVOPS_EXT_PAT"
            echo "Error: AZURE_DEVOPS_EXT_PAT environment variable is not set."
            return 1
        end
        if not command -v jq >/dev/null
            echo "Error: 'jq' is required to parse the Azure DevOps API response."
            return 1
        end
        if not command -v fzf >/dev/null
            echo "Error: 'fzf' is required for the interactive menu."
            return 1
        end

        echo "Fetching open pull requests for $repo..."

        set -l api_url "https://dev.azure.com/$org/$proj/_apis/git/repositories/$repo/pullrequests?searchCriteria.status=active&api-version=7.1"
        set -l api_response (curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$api_url")

        set -l pr_count (echo $api_response | jq -r '.value | length')
        if test -z "$pr_count" -o "$pr_count" = 0 -o "$pr_count" = null
            echo "No active PRs found, or API request failed (check if your PAT has 'Code: Read' permissions)."
            return 1
        end

        set -l fzf_preview "sh -c '$git_cmd rev-parse --verify refs/pr/{1} >/dev/null 2>&1 || $git_cmd fetch origin pull/{1}/merge:refs/pr/{1} -f >/dev/null 2>&1; pr_desc=\$(curl -s -u \":\$AZURE_DEVOPS_EXT_PAT\" \"https://dev.azure.com/$org/$proj/_apis/git/repositories/$repo/pullrequests/{1}?api-version=7.1\"); title=\$(echo \$pr_desc | jq -r \".title // empty\"); desc=\$(echo \$pr_desc | jq -r \".description // empty\"); if [ -n \"\$title\" ]; then echo \"PR #{1}: \$title\"; echo \"\"; if [ -n \"\$desc\" ]; then echo \"\$desc\"; echo \"\"; fi; echo \"---\"; echo \"\"; fi; $git_cmd log --oneline --decorate --graph --color=always refs/pr/{1}^1~3..refs/pr/{1}^2 2>/dev/null'"

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

    # Fetch PR details and discussion
    if test "$comments_only" = 1; and test -z "$AZURE_DEVOPS_EXT_PAT"
        echo "Error: AZURE_DEVOPS_EXT_PAT environment variable is not set."
        return 1
    end

    if test -n "$AZURE_DEVOPS_EXT_PAT"
        set -l pr_url "https://dev.azure.com/$org/$proj/_apis/git/repositories/$repo/pullrequests/$pr_id?api-version=7.1"
        set -l pr_details (curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$pr_url")
        set pr_title (echo $pr_details | jq -r '.title // empty' | string collect)
        set pr_description (echo $pr_details | jq -r '.description // empty' | string collect)
        set pr_status (echo $pr_details | jq -r '.status // empty')
        set source_commit (echo $pr_details | jq -r '.lastMergeSourceCommit.commitId // empty')
        set target_commit (echo $pr_details | jq -r '.lastMergeTargetCommit.commitId // empty')
        set merge_commit (echo $pr_details | jq -r '.lastMergeCommit.commitId // empty')

        if test "$output" = 0; and test "$comments_only" = 0; and test -n "$pr_title"
            echo ""
            if command -q glow
                printf '# PR #%s: %s\n' $pr_id $pr_title | glow -w 0
                if test -n "$pr_description"
                    echo ""
                    echo "$pr_description" | glow -w 0
                end
            else
                echo "PR #$pr_id: $pr_title"
                if test -n "$pr_description"
                    echo "$pr_description"
                end
            end
            echo ""
            echo ---
            echo ""
        end

        if test "$output" = 0; and test "$show_comments" = 1
            set -l threads_url "https://dev.azure.com/$org/$proj/_apis/git/repositories/$repo/pullrequests/$pr_id/threads?api-version=7.1-preview.1"
            set -l threads (curl -s -u ":$AZURE_DEVOPS_EXT_PAT" "$threads_url")
            set -l discussion (echo $threads | jq -r --argjson showSystem "$show_system" --argjson plain "$plain" '
                def col(s): if $plain == 1 then "" else "\u001b[" + s + "m" end;
                def res: if $plain == 1 then "" else "\u001b[0m" end;
                .value[]
                | select(.isDeleted != true)
                | . as $t
                | .comments[]
                | select(.isDeleted != true)
                | select($showSystem or .commentType == "text")
                | select(.author.displayName != "Microsoft.VisualStudio.Services.TFS")
                | (if (.parentCommentId // 0) > 0 then
                      "    \u21B3 "
                  else
                      col("36") + "[" + ($t.threadContext.filePath // "PR")
                      + (if $t.threadContext.rightFileStart then ":" + ($t.threadContext.rightFileStart.line|tostring) else "" end)
                      + "]" + res + " "
                  end)
                  + col("1;32") + .author.displayName + res + ": "
                  + ((.content // "") | gsub("\n"; "\n    "))
            ' | string collect)
            if test -n "$discussion"
                echo ""
                echo "Discussion:"
                echo ""
                printf '%s\n' "$discussion"
                echo ""
            end
        end
    end

    if test "$comments_only" = 1
        return 0
    end

    echo "Ensuring PR $pr_id is fully up to date..."

    set -l base_ref ""
    set -l head_ref ""

    # 1. Try fetching active virtual merge ref
    if $git_cmd fetch origin pull/$pr_id/merge:refs/pr/$pr_id -f 2>/dev/null
        set base_ref "refs/pr/$pr_id^1"
        set head_ref "refs/pr/$pr_id^2"
    else
        # 2. Fallback for completed/abandoned PRs: fetch source & target commits directly
        if test -n "$source_commit" -a -n "$target_commit"
            echo "PR is $pr_status (merge ref deleted). Fetching commit SHAs directly..."
            $git_cmd fetch origin $source_commit $target_commit >/dev/null 2>&1
            if test $status -eq 0
                set base_ref $target_commit
                set head_ref $source_commit
            end
        end

        # 3. Fallback: if merge_commit is available on target branch
        if test -z "$base_ref" -a -n "$merge_commit"
            $git_cmd fetch origin $merge_commit >/dev/null 2>&1
            if test $status -eq 0
                set base_ref "$merge_commit^1"
                set head_ref "$merge_commit"
            end
        end
    end

    if test -z "$base_ref" -o -z "$head_ref"
        echo "Failed to fetch PR $pr_id. Does it exist?"
        return 1
    end

    # Render output
    if test "$output" = 1
        set -l out_file $output_path
        if test -z "$out_file"
            set out_file ($git_cmd rev-parse --show-toplevel)/$pr_id.patch
        end
        if test -n "$pr_title"
            echo "PR #$pr_id: $pr_title" >$out_file
            if test -n "$pr_description"
                echo "$pr_description" >>$out_file
            end
        else
            echo "PR #$pr_id" >$out_file
        end
        echo "" >>$out_file
        echo --- >>$out_file
        echo "" >>$out_file
        $git_cmd log -p $base_ref..$head_ref >>$out_file
        echo "Saved patch to $out_file"
    else if test "$plain" = 1
        $git_cmd log -p $base_ref..$head_ref
    else if command -q delta
        $git_cmd diff --color=always $base_ref...$head_ref | delta
    else
        $git_cmd diff --color=always $base_ref...$head_ref | less -R
    end
end
