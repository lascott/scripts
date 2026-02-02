#!/usr/bin/env bash
#
# create_note.sh
# ---------------------------------------------------
# DESCRIPTION:
#  A utility to quickly create a new markdown note file with pre-defined template,
#  interactive selection for status and tags, and automatic population of YAML front matter.
#  It then opens the newly created file in VS Code.
#
# Options
# ---------------------------------------------------
#  -t, --title         The main title of the note. (Required)
#  -f, --filename      The base name for the markdown file (e.g., 'My New Note'). (Required)
#  -d, --description   A short description that populates the body and YAML notes. (Required)
#  -u, --url           A URL to include in the note. (Required)
#  -c, --open-code     Boolean. If 'true' (default), opens the file in VS Code. If 'false', does not open.
#  -h, --help          Display this help and exit.
#
# NOTES:
# ---------------------------------------------------
#  - Uses bash strict mode for robust scripting.
#  - Requires 'code' command (VS Code) to be in your PATH for --open-code true.
#
# AUTHOR: lascott 
# 
# Copyright (c) 2026 louis scott
# MIT License
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# --- Shell Configuration (Bash Strict Mode) ---
set -o errexit    # Exit immediately if a command exits with a non-zero status.
set -o nounset    # Treat unset variables as an error when substituting.
set -o pipefail   # The return value of a pipeline is the status of the last command to exit with a non-zero status.

# --- Global Constants ---
readonly STATUS_OPTIONS=("idea" "read" "plan" "progress" "implement")


# --- Global Variables (will be populated by functions) ---
declare SCRIPT_TITLE=""
declare FILENAME_BASE=""
declare NOTE_DESCRIPTION=""
declare NOTE_URL=""
declare OPEN_IN_CODE=true # Default to true
declare SELECT_STATUS=""
declare -a SELECTED_TAGS=() # Array for selected tags


# --- Function Definitions ---

# Prints usage information and exits.
usage() {
    echo "Usage: $0 --title <title> --filename <filename_base> --description <description> --url <url> [--open-code <true|false>]"
    echo ""
    echo "Options:"
    echo "  -t, --title        The main title of the note. (Required)"
    echo "  -f, --filename     The base name for the markdown file (e.g., 'My New Note'). (Required)"
    echo "  -d, --description  A short description that populates the body and YAML notes. (Required)"
    echo "  -u, --url          A URL to include in the note. (Required)"
    echo "  -c, --open-code    Boolean. If 'true' (default), opens the file in VS Code. If 'false', does not open."
    echo "  -h, --help         Display this help and exit."
    echo ""
    exit 1
}

# Ensures the 'code' command for VS Code is available.
check_dependencies() {
    if ! command -v code &> /dev/null; then
        echo "Error: 'code' command (VS Code) not found. Please ensure it's in your PATH." >&2
        # Do not exit if OPEN_IN_CODE is false, only warn
        if [[ "${OPEN_IN_CODE}" == "true" ]]; then
            exit 1
        else
            echo "Warning: VS Code will not be launched as 'code' command is missing and --open-code is true. To suppress this warning, use --open-code false." >&2
        fi
    fi
}




# Parses command-line arguments and populates global variables.
# Arguments: "$@" (all script arguments)
parse_arguments() {
    local -a positional_args=()

    while [ "${1:-}" != "" ]; do
        case "${1:-}" in
            -t | --title )
                shift
                SCRIPT_TITLE="$1"
                ;;
            -f | --filename )
                shift
                FILENAME_BASE="$1"
                ;;
            -d | --description )
                shift
                NOTE_DESCRIPTION="$1"
                ;;
            -u | --url )
                shift
                NOTE_URL="$1"
                ;;
            -c | --open-code )
                shift
                if [[ "$1" =~ ^(true|false)$ ]]; then
                    OPEN_IN_CODE="$1"
                else
                    echo "Error: --open-code must be 'true' or 'false'." >&2
                    usage
                fi
                ;;
            -h | --help )
                usage
                ;;
            * )
                positional_args+=("$1")
                ;;
        esac
        shift
    done

    # Check for unhandled positional arguments (shouldn't be any with explicit options)
    if [ "${#positional_args[@]}" -gt 0 ]; then
        echo "Error: Unrecognized arguments: '${positional_args[*]}'" >&2
        usage
    fi

    # Check if all required arguments are provided
    if [ -z "${SCRIPT_TITLE}" ] || [ -z "${FILENAME_BASE}" ] || [ -z "${NOTE_DESCRIPTION}" ] || [ -z "${NOTE_URL}" ]; then
        echo "Error: Required options (--title, --filename, --description, --url) are missing." >&2
        usage
    fi
}

# Interactively prompts the user to select a single status.
# Populates the global variable SELECT_STATUS.
select_status() {
    echo "--- Select Status ---"
    local i
    for i in "${!STATUS_OPTIONS[@]}"; do
        echo "$((i+1))). ${STATUS_OPTIONS[$i]}"
    done

    local choice
    while true; do
        read -rp "Choose a status (enter number): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#STATUS_OPTIONS[@]} )); then
            SELECT_STATUS="${STATUS_OPTIONS[$((choice-1))]}"
            echo "Selected Status: ${SELECT_STATUS}"
            echo ""
            break
        else
            echo "Invalid selection. Please enter a number from 1 to ${#STATUS_OPTIONS[@]}." >&2
        fi
    done
}



# Generates the markdown file content and writes it to a file.
# Arguments: sanitized_filename, markdown_filename
generate_and_write_markdown() {
    local sanitized_filename="$1"
    local markdown_filename="$2"

    local today
    today=$(date +"%Y-%m-%d")
    local id_date
    id_date=$(date +"%Y%m%d%H%M")

    local formatted_tags=""
    if [ ${#SELECTED_TAGS[@]} -gt 0 ]; then
        local tag
        for tag in "${SELECTED_TAGS[@]}"; do
            formatted_tags+="[[${tag}]] "
        done
        formatted_tags="${formatted_tags% }" # Remove trailing space
    fi
    
    local yaml_tags="[]" # Default to empty array for YAML
    if [ ${#SELECTED_TAGS[@]} -gt 0 ]; then
        local internal_tags
        internal_tags=$(printf "%s, " "${SELECTED_TAGS[@]}")
        internal_tags="${internal_tags%, }" # Remove trailing comma and space
        yaml_tags="[${internal_tags}]"
    fi

    # Using HEREDOC for cleaner template definition
    local template_content=$(cat <<EOF
---
id: ${id_date}
created_date: ${today}
updated_date: ${today}
---
Status: ${SELECT_STATUS}
Tags: ${formatted_tags}
---
## ${SCRIPT_TITLE}
${NOTE_DESCRIPTION}

[url](${NOTE_URL})
_______

References

\`\`\`yaml
data:
  title: "${SCRIPT_TITLE}"
  type: note
  tags: ${yaml_tags}
  status: ${SELECT_STATUS}
  notes: |
    # ${SCRIPT_TITLE}
    
    ${NOTE_DESCRIPTION}
\`\`\`
EOF
)
    echo "${template_content}" > "${markdown_filename}"
}


# Orchestrates the script's execution.
main() {
    # Set IFS for robust word splitting
    IFS=$'\n\t'

    # Check dependencies and parse arguments first
    parse_arguments "$@" # Pass all arguments to parse_arguments
    check_dependencies

    local sanitized_filename
    sanitized_filename=$(echo "${FILENAME_BASE}" | sed -r 's/[^a-zA-Z0-9 _-]//g' | sed 's/ /_/g')
    local markdown_filename="${sanitized_filename}.md"

    select_status
    IFS=',' read -r -a SELECTED_TAGS <<< "$('./select_tags.sh')"

    generate_and_write_markdown "${sanitized_filename}" "${markdown_filename}"

    echo "Successfully created ${markdown_filename}"

    if [[ "${OPEN_IN_CODE}" == "true" ]]; then
        echo "Launching VS Code with ${markdown_filename}..."
        code "${markdown_filename}"
    else
        echo "Skipping VS Code launch as --open-code is set to 'false'."
    fi
}

# Execute the main function with all script arguments
main "$@"
