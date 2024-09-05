#!/bin/bash

# Set the Gemini API URL and API key
GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
API_KEY="AIzaSyA2RwjvzfJgaTPUglnZue9DLI194yTcoAE"  # Replace with your actual API key

# Get the list of all changes: modified, untracked, and deleted files
files=$(git ls-files --modified --others --deleted --exclude-standard)

# Exit if no files are found
if [ -z "$files" ]; then
    echo "No changes to commit."
    exit 1
fi

# Function to send detailed file changes to Gemini API and get the commit suggestion and message
get_commit_message_from_gemini() {
    local diff_summary=$1
    local commit_type=$2  # Pass the default commit type (feat or fix)

    # Ask Gemini for a short commit message prefixed with feat: or fix:
    prompt="Provide a short, one-line commit message prefixed with '$commit_type:' summarizing the following change: $diff_summary"

    # Replace newlines with a space and escape quotes for JSON compatibility
    prompt=$(echo "$prompt" | tr '\n' ' ' | sed 's/"/\\"/g')

    # Send the prompt to the Gemini API and capture the response
    response=$(curl -s -X POST "$GEMINI_API_URL?key=$API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
                "contents": [
                    {
                        "parts": [
                            {
                                "text": "'"$prompt"'"
                            }
                        ]
                    }
                ]
            }')

    # Ensure the response is valid and has the "text" field
    if [[ ! "$response" =~ "text" ]]; then
        echo "$commit_type: default commit message generated"
        return
    fi

    # Extract only the first part of the commit message
    commit_message=$(echo "$response" | grep -o '"text": *"[^"]*"' | sed -e 's/"text": *"//' -e 's/"$//' | tr -d '\n')

    # If the commit message is empty, use a default message
    if [[ -z "$commit_message" ]]; then
        echo "$commit_type: default commit message generated"
        return
    fi

    # Ensure the commit message starts with the correct prefix (feat: or fix:)
    if [[ "$commit_type" == "feat" && "$commit_message" != feat* ]]; then
        commit_message="feat: $commit_message"
    elif [[ "$commit_type" == "fix" && "$commit_message" != fix* ]]; then
        commit_message="fix: $commit_message"
    fi

    # Trim the commit message to 72 characters, ensuring we don't cut words in half
    commit_message=$(echo "$commit_message" | awk '{ if (length($0) > 72) { print substr($0, 1, 72); } else { print $0; } }' | sed 's/ *$//')

    # Return the cleaned-up commit message
    echo "$commit_message"
}

# Loop through each file and determine the type of change
for file in $files
do
    # Get only the file name
    filename=$(basename "$file")

    # Initialize variables for diff summary
    diff_summary=""
    commit_type=""

    if git ls-files --deleted | grep -q "$file"; then
        # For deleted files, show what was removed
        diff_summary="File '$file' has been deleted."
        commit_type="refactor"
    elif git ls-files --others --exclude-standard | grep -q "$file"; then
        # For new files, show the content of the new file
        diff_summary="New file '$file' created with the following content: $(cat "$file")"
        commit_type="feat"  # New files are generally considered a new feature
    else
        # For modified files, get the diff between the old and new content
        diff_summary=$(git diff "$file")
        if [ -z "$diff_summary" ]; then
            diff_summary="File '$file' has been updated, but no significant changes detected."
        fi
        commit_type="fix"  # Modified files are generally considered a fix
    fi

    # Ask Gemini API for a commit suggestion based on the detailed diff summary
    commit_message=$(get_commit_message_from_gemini "$diff_summary" "$commit_type")

    # Generate the commit message using the response from the Gemini API
    commit_message="${commit_message:-$commit_type: update $filename}"

    # Ensure untracked files are added properly
    if git ls-files --others --exclude-standard | grep -q "$file"; then
        git add "$file"
    fi

    # Stage and commit
    if [[ "$commit_message" == *"delete"* ]]; then
        git rm "$file"
    else
        git add "$file"
    fi

    git commit -m "$commit_message"
    echo "Committed $filename with message: $commit_message"
done
