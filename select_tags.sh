#!/usr/bin/env bash
#
# select_tags.sh
#
# A utility to interactively select multiple tags from a JSON file, supporting hierarchical tags.
# It outputs the selected tags as a comma-separated string.
#
# Options
# ---------------------------------------------------
#  -t, --tags-file    Path to the JSON file containing tags (e.g., 'all_tags.json').
#                     Defaults to 'all_tags.json' in the current directory.
#  --test-mode        Activates test mode, where input is read from --test-responses.
#  --test-responses   Comma-separated string of responses for test mode. (e.g., "1,3,1 4,4,1 3,done")
#  -h, --help         Display this help and exit.
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

# --- Shell Configuration ---
set -o errexit
set -o nounset
set -o pipefail

# --- Global Variables ---
declare -a TOP_LEVEL_TAG_NAMES=() # For display: e.g., "YT", "maths", "Coding"
declare -a TOP_LEVEL_TAG_OBJS=() # Raw JSON objects for each tag
declare -a SELECTED_TAGS=()

readonly TAGS_FILE="all_tags.json" # Pointing to the project's actual JSON file

declare TEST_MODE=false
declare -a TEST_RESPONSES=()
declare TEST_RESPONSE_INDEX=0

# --- Function Definitions ---

# Prints usage information and exits.
usage() {
    echo "Usage: $0 [--tags-file <path_to_json>] [--test-mode [--test-responses <responses>]]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  -t, --tags-file    Path to the JSON file containing tags. Defaults to 'all_tags.json'." >&2
    echo "  --test-mode        Activates test mode, reading input from --test-responses." >&2
    echo "  --test-responses   Comma-separated string of responses for test mode (e.g., '1,3,1 4,4,1 3,done')." >&2
    echo "  -h, --help         Display this help and exit." >&2
    echo "" >&2
    exit 1
}

# Reads input based on TEST_MODE.
# Arguments: $1: prompt_message
# Returns: input via echo, sets global INPUT_VAR.
get_input() {
    local prompt_message="$1"
    local input_val=""

    if "${TEST_MODE}"; then
        if (( TEST_RESPONSE_INDEX < ${#TEST_RESPONSES[@]} )); then
            input_val="${TEST_RESPONSES[$TEST_RESPONSE_INDEX]}"
            echo "TEST_MODE Input [${TEST_RESPONSE_INDEX}]: $input_val" >&2
            TEST_RESPONSE_INDEX=$((TEST_RESPONSE_INDEX + 1))
        else
            echo "Error: Test responses exhausted in TEST_MODE." >&2
            exit 1
        fi
    else
        read -rp "$prompt_message" input_val
    fi
    echo "$input_val" # Return value
}


# Loads tags from the JSON file into the global arrays.
# It populates TOP_LEVEL_TAG_NAMES for the menu display
# and TOP_LEVEL_TAG_OBJS to hold the full JSON data for each item.
load_tags() {
    if ! command -v jq &> /dev/null; then
        echo "Error: 'jq' is required for hierarchical tag selection. Please install jq." >&2
        exit 1
    fi

    if [ ! -f "$TAGS_FILE" ]; then
        echo "Error: Tags file '$TAGS_FILE' not found." >&2
        exit 1
    fi

    # Read the name of each top-level tag into an array.
    # If the item is a string, use it directly.
    # If it's an object, use its .name property.
    readarray -t TOP_LEVEL_TAG_NAMES < <(jq -r '.[] | if type=="string" then . else .name end' "$TAGS_FILE")

    # Read the raw JSON for each top-level tag into an array.
    # This allows us to inspect for subtags later.
    readarray -t TOP_LEVEL_TAG_OBJS < <(jq -c '.[]' "$TAGS_FILE")
}

# Checks if a tag is already in the SELECTED_TAGS array.
# Arguments: $1: tag_name
# Returns 0 if present, 1 if not.
is_tag_selected() {
    local tag_to_check="$1"
    local t
    for t in "${SELECTED_TAGS[@]}"; do
        if [[ "$t" == "$tag_to_check" ]]; then
            return 0
        fi
    done
    return 1
}

# Adds a tag to the SELECTED_TAGS array if it's not already there.
# Arguments: $1: tag_name
add_tag() {
    if ! is_tag_selected "$1"; then
        SELECTED_TAGS+=("$1")
    fi
}

# Displays a menu for subtags and handles user selection.
# Arguments: $1: parent_tag_name
# The rest of the arguments ($@) are the subtags.
select_subtags() {
    local parent_name="$1"
    shift # Remove parent name from arguments, leaving only subtags
    local -a subtags=("$@")

    echo "--- Select Sub-Tags for '$parent_name' (enter numbers separated by spaces, or 'done') ---" >&2
    
    local i
    local count=0 # New counter for formatting
    for i in "${!subtags[@]}"; do
        printf "%2d). %-12s " "$((i+1))" "${subtags[$i]}" >&2
        count=$((count + 1))
        if (( count % 5 == 0 )); then
            echo "" >&2
        fi
    done
    if (( count % 5 != 0 )); then # Ensure final newline if not a multiple of 5
        echo "" >&2
    fi
    echo "" >&2

    while true; do
        local SUB_INPUT
        SUB_INPUT="$(get_input "Choose sub-tags for '$parent_name': ")"
        if [[ "$SUB_INPUT" =~ ^[Dd][Oo][Nn][Ee]$ ]]; then
            break
        fi

        local -a CHOICES
        IFS=' ' read -ra CHOICES <<< "$SUB_INPUT"
        local choice
        for choice in "${CHOICES[@]}"; do
            if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#subtags[@]} )); then
                echo "Invalid sub-tag choice: '$choice'" >&2
                continue
            fi
            
            # Add the parent tag first
            add_tag "$parent_name"
            # Add the selected subtag
            add_tag "${subtags[$((choice-1))]}"
        done
        echo "Currently selected: ${SELECTED_TAGS[*]}" >&2
        break # Exit after one selection of subtags and return to main menu
    done
}


# --- Main Execution ---
main() {
    # Parse arguments for tags file and test mode
    local -a positional_args=()
    local responses_string=""

    while [ "${1:-}" != "" ]; do
        case "${1:-}" in
            -t | --tags-file )
                shift
                TAGS_FILE="$1"
                ;;
            --test-mode )
                TEST_MODE=true
                ;;
            --test-responses )
                shift
                responses_string="$1"
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

    # If in test mode, populate TEST_RESPONSES
    if "${TEST_MODE}"; then
        if [ -z "$responses_string" ]; then
            echo "Error: --test-responses is required when --test-mode is active." >&2
            usage
        fi
        IFS=',' read -ra TEST_RESPONSES <<< "$responses_string"
    fi

    load_tags

    while true; do
        echo "--- Select Tags (enter numbers separated by spaces, or 'done') ---" >&2
        
        local i
        local count=0 # New counter for formatting
        for i in "${!TOP_LEVEL_TAG_NAMES[@]}"; do
            printf "%2d). %-12s " "$((i+1))" "${TOP_LEVEL_TAG_NAMES[$i]}" >&2
            count=$((count + 1))
            if (( count % 5 == 0 )); then
                echo "" >&2
            fi
        done
        if (( count % 5 != 0 )); then # Ensure final newline if not a multiple of 5
            echo "" >&2
        fi
        echo "" >&2
        
        echo "Currently selected: ${SELECTED_TAGS[*]}" >&2
        local INPUT_LINE
        INPUT_LINE="$(get_input "Choose tags: ")"

        if [[ "$INPUT_LINE" =~ ^[Dd][Oo][Nn][Ee]$ ]]; then
            break
        fi

        local -a CHOICES
        IFS=' ' read -ra CHOICES <<< "$INPUT_LINE"

        local choice_index=0
        while (( choice_index < ${#CHOICES[@]} )); do
            local choice="${CHOICES[$choice_index]}"

            if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#TOP_LEVEL_TAG_NAMES[@]} )); then
                echo "Invalid choice: '$choice'." >&2
                choice_index=$((choice_index + 1))
                continue
            fi

            local index=$((choice-1))
            local tag_obj_json="${TOP_LEVEL_TAG_OBJS[$index]}"

            if (( $(echo "$tag_obj_json" | jq 'if type=="object" and .subtags then 1 else 0 end') == 1 )); then
                local parent_name
                parent_name=$(echo "$tag_obj_json" | jq -r '.name')
                
                # Add parent tag immediately.
                add_tag "$parent_name"
                
                local -a subtags_arr
                readarray -t subtags_arr < <(echo "$tag_obj_json" | jq -r '.subtags[]')
                
                select_subtags "$parent_name" "${subtags_arr[@]}"
            else
                add_tag "${TOP_LEVEL_TAG_NAMES[$index]}"
            fi

            choice_index=$((choice_index + 1))
        done
    done

    # Final output: a flat, comma-separated list of all selected tags.
    # This is the "contract" with the calling script.
    (IFS=,; echo "${SELECTED_TAGS[*]}")
}

main "$@"
