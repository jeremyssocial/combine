#!/usr/bin/env bash

set -euo pipefail

VERSION="1.1.2"

# Default settings
output_file="combined_output.md"
full_output_path=""
verbose=false
max_file_size=$((10 * 1024 * 1024))  # 10 MB
exclude_dirs=()
processed_dirs=()

# Function to display usage information
usage() {
    echo "Usage: $0 [-o output_file] [-s max_file_size] [-e exclude_dir] [-v] [-h] [-V]"
    echo "  -o output_file    Specify the output file name (default: combined_output.md)"
    echo "  -s max_file_size  Set maximum file size to process in bytes (default: 10MB)"
    echo "  -e exclude_dir    Specify a directory to exclude (can be used multiple times)"
    echo "  -v                Enable verbose mode"
    echo "  -h                Display this help message"
    echo "  -V                Display version information"
    exit 1
}

# Function to display version information
version() {
    echo "combine.sh version $VERSION"
    exit 0
}

# Parse command-line options
while getopts ":o:s:e:vhV" opt; do
    case ${opt} in
        o )
            output_file=$OPTARG
            ;;
        s )
            max_file_size=$OPTARG
            ;;
        e )
            exclude_dirs+=("$OPTARG")
            ;;
        v )
            verbose=true
            ;;
        h )
            usage
            ;;
        V )
            version
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

full_output_path="$(pwd)/$output_file"

# Function to log messages in verbose mode
log() {
    if [ "$verbose" = true ]; then
        echo "$@"
    fi
}

# Function to check for required tools
check_required_tools() {
    local tools=("tree" "pandoc" "pdftotext" "jq" "highlight" "exiftool")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
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
    tree -a -I "$output_file" > "$output_file"
    echo -e "\n\n" >> "$output_file"
}

# Function to process a single file
process_file() {
    local file="$1"
    local file_size

    if [ "$(realpath "$file")" = "$full_output_path" ]; then
        return
    fi

    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    if [ "$file_size" -gt "$max_file_size" ]; then
        log "Skipping $file: file size ($file_size bytes) exceeds maximum ($max_file_size bytes)"
        return
    fi

    log "Processing $file"
    echo -e "## ${file}\n" >> "$output_file"

    if file "$file" | grep -q text; then
        echo -e "\`\`\`\n$(cat "$file")\n\`\`\`\n" >> "$output_file"
    elif file "$file" | grep -qi pdf; then
        echo -e "\`\`\`\n$(pdftotext "$file" -)\n\`\`\`\n" >> "$output_file"
    elif file "$file" | grep -qi json; then
        echo -e "\`\`\`json\n$(jq . "$file")\n\`\`\`\n" >> "$output_file"
    elif file "$file" | grep -q 'script' || file "$file" | grep -q 'source'; then
        echo -e "\`\`\`\n$(highlight -O ansi "$file")\n\`\`\`\n" >> "$output_file"
    elif file "$file" | grep -qiE 'msword|openxmlformats'; then
        echo -e "\`\`\`\n$(pandoc "$file" -t markdown)\n\`\`\`\n" >> "$output_file"
    elif file "$file" | grep -qiE 'image|bitmap'; then
        echo -e "\`\`\`\n$(exiftool "$file")\n\`\`\`\n" >> "$output_file"
    else
        log "Skipping unsupported file type: $file"
    fi
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

    for item in "$current_dir"/*; do
        if [ -d "$item" ]; then
            if [ -L "$item" ]; then
                log "Skipping symlinked directory: $item"
            else
                process_files "$item"
            fi
        elif [ -f "$item" ]; then
            process_file "$item"
        fi
    done
}

# Main execution
main() {
    check_required_tools
    generate_tree
    process_files "."
    echo "Done! Combined output is in $output_file"
}

main