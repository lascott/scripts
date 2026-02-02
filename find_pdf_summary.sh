#!/usr/bin/env bash
#
# find_pdf_summary.sh
# ---------------------------------------------------
# DESCRIPTION:
#  Finds and echoes the first non-empty summary line from a PDF file
#  using a predefined set of extraction commands.
#
# Options
# ---------------------------------------------------
#  -n, --nlines <num>    Number of lines to output for the summary (default: 6)
#  -h, --help            display this help and exit
#
# NOTES:
# ---------------------------------------------------
#  This script relies on 'pdf_summary.sh' and 'pdftotext' to be available
#  in the system's PATH or the current directory.
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

# Function to display usage information
usage () {
    echo "Usage: $0 [OPTIONS] <pdf_filename>"
    echo ""
    echo "Options:"
    echo "  -n, --nlines <num>    Number of lines to output for the summary (default: 6)"
    echo "  -h, --help            Display this help and exit"
    echo ""
    echo "Arguments:"
    echo "  <pdf_filename>: The path to the PDF file to process."
    exit 1
}

# Function to find the first non-empty summary from the PDF
find_summary() {
    local PDF_FILENAME="$1"
    local NLINES="$2"
    local FOUND_OUTPUT=""

    # Define the commands to execute, using the provided PDF_FILENAME
    # looking for summary, abstract, introduction sections
    local COMMANDS=(
        "./pdf_summary.sh '$PDF_FILENAME' 1 2 - | grep -A 5 ntroduction | head -n $NLINES"
        "./pdf_summary.sh '$PDF_FILENAME' 1 2 - | grep -A 5 bstract | head -n $NLINES"
        "./pdf_summary.sh '$PDF_FILENAME' 1 2 - | grep -A 5 ummary | head -n $NLINES"
        "./pdf_summary.sh '$PDF_FILENAME' 1 2 - | head -n $NLINES"
    )

    # Loop through the commands and execute them
    for cmd in "${COMMANDS[@]}"; do
        # Execute the command and capture its output
        # Using 'eval' because the commands themselves contain pipes and redirection
        local OUTPUT=$(eval "$cmd")

        # Check if the output is not empty
        if [ -n "$OUTPUT" ]; then
            FOUND_OUTPUT="$OUTPUT"
            break # Exit loop after finding the first non-empty output
        fi
    done

    echo "$FOUND_OUTPUT"
}

# Main function
main() {
    # bash strict mode
    set -euo pipefail
    IFS=$'\n\t'

    local NLINES=6 # Default number of lines
    local PDF_FILENAME=""

    # Parse command-line arguments
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -n | --nlines )
                if [ -z "$2" ]; then
                    echo "Error: Argument for $1 is missing." >&2
                    usage
                fi
                NLINES="$2"
                shift 2
                ;;
            -h | --help )
                usage
                ;;
            -* )
                echo "Error: Unknown option $1" >&2
                usage
                ;;
            * ) # Positional argument (filename)
                if [ -n "$PDF_FILENAME" ]; then
                    echo "Error: Multiple PDF filenames provided." >&2
                    usage
                fi
                PDF_FILENAME="$1"
                shift
                ;;
        esac
    done

    # Check if PDF filename is provided
    if [ -z "$PDF_FILENAME" ]; then
        echo "Error: PDF filename not provided." >&2
        usage
    fi

    # Check if the PDF file exists
    if [ ! -f "$PDF_FILENAME" ]; then
        echo "Error: File '$PDF_FILENAME' not found." >&2
        exit 1
    fi

    # Call the function to find and print the summary
    find_summary "$PDF_FILENAME" "$NLINES"
}

# Call the main function with all script arguments
main "$@"
