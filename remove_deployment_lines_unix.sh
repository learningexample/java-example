#!/bin/bash

remove_deployment_lines() {
    local filename="$1"
    
    if [ -z "$filename" ]; then
        echo "Error: No filename provided to remove_deployment_lines()"
        return 1
    fi
    
    if [ ! -f "$filename" ]; then
        echo "Error: File '$filename' not found"
        return 1
    fi
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Use sed to remove lines between markers (exclusive - keep the markers)
    sed '/\/\/Deployment/,/\/\/End-Of-Deployment/{/\/\/Deployment/!{/\/\/End-Of-Deployment/!d}}' "$filename" > "$temp_file"
    
    # Replace original file with modified content
    mv "$temp_file" "$filename"
    
    echo "Removed deployment sections from $filename"
    return 0
}

# If script is run directly (not sourced), execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <filename>"
        echo "Removes content between //Deployment and //End-Of-Deployment markers (keeping the markers)"
        exit 1
    fi
    
    remove_deployment_lines "$1"
fi