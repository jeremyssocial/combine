#!/usr/bin/env bash

set -euo pipefail

VERSION="2.0.0"

# Default settings
output_file="combined_output.md"
json_output_file=""
full_output_path=""
verbose=false
max_file_size=$((10 * 1024 * 1024)) # 10 MB
exclude_dirs=()
exclude_extensions=()
processed_dirs=()
respect_gitignore=false
calculate_tokens=false

# Function to display usage information
usage() {
    echo "Usage: $0 [-o output_file] [-j json_output] [-s max_file_size] [-e exclude_dir] [-x exclude_extension] [-v] [-h] [-V] [--gitignore] [--tokens]"
    echo "  -o output_file      Specify the output Markdown file name (default: combined_output.md)"
    echo "  -j json_output      Specify the output JSON file name (optional)"
    echo "  -s max_file_size    Set maximum file size to process in bytes (default: 10MB)"
    echo "  -e exclude_dir      Specify a directory to exclude (can be used multiple times)"
    echo "  -x exclude_extension Specify a file extension to exclude (can be used multiple times)"
    echo "  -v                  Enable verbose mode"
    echo "  -h                  Display this help message"
    echo "  -V                  Display version information"
    echo "  --gitignore         Respect all .gitignore files when processing directories"
    echo "  --tokens            Calculate and display token count for the output file"
    exit 1
}

# Function to display version information
version() {
    echo "combine.sh version $VERSION"
    exit 0
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case $1 in
    -o)
        output_file="$2"
        shift 2
        ;;
    -j)
        json_output_file="$2"
        shift 2
        ;;
    -s)
        max_file_size="$2"
        shift 2
        ;;
    -e)
        exclude_dirs+=("$2")
        shift 2
        ;;
    -x)
        exclude_extensions+=("$2")
        shift 2
        ;;
    -v)
        verbose=true
        shift
        ;;
    -h)
        usage
        ;;
    -V)
        version
        ;;
    --gitignore)
        respect_gitignore=true
        shift
        ;;
    --tokens)
        calculate_tokens=true
        shift
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage
        ;;
    esac
done

full_output_path="$(pwd)/$output_file"

# Function to log messages in verbose mode
log() {
    if [ "$verbose" = true ]; then
        echo "$@"
    fi
}

# Function to check for required tools
check_required_tools() {
    local tools=("tree" "pandoc" "pdftotext" "jq" "highlight" "exiftool" "git")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Error: The following required tools are missing:" >&2
        printf " - %s\n" "${missing_tools[@]}" >&2
        echo "Please install them before running this script." >&2
        exit 1
    fi
}

# Generate ASCII representation of the folder structure
generate_tree() {
    log "Generating directory tree..."
    if [ "$respect_gitignore" = true ]; then
        git ls-files | tree --fromfile -a -I "$output_file" >"$output_file"
    else
        tree -a -I "$output_file" >"$output_file"
    fi
    echo -e "\n\n" >>"$output_file"
}

# Function to process a single file
process_file() {
    local file="$1"
    local file_size

    if [ "$(realpath "$file")" = "$full_output_path" ]; then
        return
    fi

    # Check if file extension is excluded
    local extension="${file##*.}"
    if [[ " ${exclude_extensions[@]} " =~ " ${extension} " ]]; then
        log "Skipping $file: extension $extension is excluded"
        return
    fi

    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    if [ "$file_size" -gt "$max_file_size" ]; then
        log "Skipping $file: file size ($file_size bytes) exceeds maximum ($max_file_size bytes)"
        return
    fi

    local mime_type
    mime_type=$(file -b --mime-type "$file")

    log "Processing $file (MIME type: $mime_type)"
    echo -e "## ${file}\n" >>"$output_file"

    case "$mime_type" in
    text/* | application/json | application/javascript | application/x-javascript | application/typescript)
        echo -e "\`\`\`\n$(cat "$file")\n\`\`\`\n" >>"$output_file"
        ;;
    application/pdf)
        echo -e "\`\`\`\n$(pdftotext "$file" -)\n\`\`\`\n" >>"$output_file"
        ;;
    application/x-shellscript | application/x-php)
        echo -e "\`\`\`\n$(highlight -O ansi "$file")\n\`\`\`\n" >>"$output_file"
        ;;
    application/msword | application/vnd.openxmlformats-officedocument.wordprocessingml.document)
        echo -e "\`\`\`\n$(pandoc "$file" -t markdown)\n\`\`\`\n" >>"$output_file"
        ;;
    image/*)
        echo -e "Image file: $file\n\`\`\`\n$(exiftool "$file")\n\`\`\`\n" >>"$output_file"
        ;;
    application/octet-stream | inode/x-empty)
        log "Skipping binary or empty file: $file"
        ;;
    *)
        log "Unsupported file type ($mime_type): $file"
        echo -e "Unsupported file type: $file (MIME type: $mime_type)\n" >>"$output_file"
        ;;
    esac
}

# Function to check if a file should be ignored based on all .gitignore files
should_ignore() {
    local file="$1"

    if [ "$respect_gitignore" = false ]; then
        return 1
    fi

    if git check-ignore -q "$file" 2>/dev/null; then
        return 0
    fi

    return 1
}

# Function to check if a directory should be excluded
should_exclude() {
    local dir="$1"
    if [ ${#exclude_dirs[@]} -eq 0 ]; then
        return 1
    fi
    for exclude in "${exclude_dirs[@]}"; do
        if [[ "$dir" == *"$exclude"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if a directory has been processed
is_processed() {
    local dir="$1"
    if [ ${#processed_dirs[@]} -eq 0 ]; then
        return 1
    fi
    for processed in "${processed_dirs[@]}"; do
        if [[ "$dir" == "$processed" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to process files recursively
process_files() {
    local current_dir="$1"
    local real_path

    real_path=$(realpath "$current_dir")

    if should_exclude "$real_path" || is_processed "$real_path"; then
        log "Skipping excluded or already processed directory: $current_dir"
        return
    fi

    processed_dirs+=("$real_path")

    if [ "$respect_gitignore" = true ]; then
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                process_file "$file"
            elif [ -d "$file" ]; then
                process_files "$file"
            fi
        done < <(git ls-files "$current_dir")
    else
        while IFS= read -r -d '' file; do
            if [ -d "$file" ]; then
                if [ -L "$file" ]; then
                    log "Skipping symlinked directory: $file"
                else
                    process_files "$file"
                fi
            elif [ -f "$file" ]; then
                process_file "$file"
            fi
        done < <(find "$current_dir" -maxdepth 1 -print0)
    fi
}

# Function to calculate tokens
calculate_tokens() {
    local file="$1"
    local word_count=$(wc -w <"$file")
    local estimated_tokens=$((word_count * 4 / 3))
    echo "Estimated token count: $estimated_tokens"
}

# Function to generate JSON output
generate_json() {
    local md_file="$1"
    local json_file="$2"
    jq -n --arg content "$(cat "$md_file")" '{"content": $content}' >"$json_file"
    echo "JSON output generated: $json_file"
}

# Main execution
main() {
    check_required_tools
    generate_tree
    process_files "."
    echo "Done! Combined output is in $output_file"

    if [ "$calculate_tokens" = true ]; then
        calculate_tokens "$output_file"
    fi

    if [ -n "$json_output_file" ]; then
        generate_json "$output_file" "$json_output_file"
    fi
}

main
