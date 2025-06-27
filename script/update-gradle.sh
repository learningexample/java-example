#!/bin/bash

# Check if exactly four parameters are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 <searchPath> <name> <newValue> <baseBranch>"
    exit 1
fi

# Assign parameters to variables
searchPath="$1"
name="$2"
newValue="$3"
baseBranch="$4"
newBranch="${baseBranch}-${name}-${newValue}"

# Check if the search path exists and is a directory
if [ ! -d "$searchPath" ]; then
    echo "Error: $searchPath is not a valid directory"
    exit 1
fi

# Find all directories containing a .git folder within the specified path
find "$searchPath" -type d -name ".git" | while read -r git_dir; do
    # Get the parent directory of .git (the repo root)
    repo_dir=$(dirname "$git_dir")
    # Navigate two levels up from .git directory
    parent_dir=$(dirname "$repo_dir")
    
    echo "Processing repository in $repo_dir"
    
    # Change to the repository directory
    cd "$repo_dir" || continue
    
    # Check if baseBranch exists
    if git show-ref --verify --quiet "refs/heads/$baseBranch"; then
        # Checkout the base branch
        git checkout "$baseBranch" || {
            echo "Failed to checkout $baseBranch in $repo_dir"
            cd - >/dev/null
            continue
        }
        
        # Pull latest changes
        git pull origin "$baseBranch" || {
            echo "Failed to pull $baseBranch in $repo_dir"
            cd - >/dev/null
            continue
        }
        
        # Check if gradle.properties exists in the parent directory
        file="$parent_dir/gradle.properties"
        if [ -f "$file" ]; then
            # Check if the property exists in the file
            if grep -q "^$name=" "$file"; then
                # Replace the existing property value
                sed -i "s/^$name=.*/$name=$newValue/" "$file"
                echo "Updated $name to $newValue in $file"
            else
                # Append the new property if it doesn't exist
                echo "$name=$newValue" >> "$file"
                echo "Added $name=$newValue to $file"
            }
            
            # Create and checkout new branch
            git checkout -b "$newBranch" || {
                echo "Failed to create branch $newBranch in $repo_dir"
                cd - >/dev/null
                continue
            }
            
            # Since gradle.properties is outside the git repo, copy it to the repo directory
            cp "$file" .
            git add "gradle.properties"
            git commit -m "Update $name to $newValue in gradle.properties" || {
                echo "Failed to commit changes in $repo_dir"
                cd - >/dev/null
                continue
            }
            
            # Push new branch to remote
            git push origin "$newBranch" || {
                echo "Failed to push $newBranch to remote in $repo_dir"
                cd - >/dev/null
                continue
            }
            
            echo "Successfully updated and pushed changes to $newBranch in $repo_dir"
        else
            echo "No gradle.properties found in $parent_dir"
        fi
        
        # Return to original branch
        git checkout "$baseBranch" >/dev/null
    else
        echo "Base branch $baseBranch does not exist in $repo_dir"
    fi
    
    # Return to the original directory
    cd - >/dev/null
done