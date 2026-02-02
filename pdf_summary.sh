#!/bin/bash

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

pattern="$1"
first="$2"
last="$3"
output_file="$4"


# Check for help flag
if [[ "$pattern" == "-h" || "$pattern" == "--help" ]]; then
    echo "Usage: $0 <pattern> <first> <last> [output_file]"
    echo "  <pattern>: File pattern to match"
    echo "  <first>: First page to extract"
    echo "  <last>: Last page to extract"
    echo "  <output_file>: Output file (or '-' for stdout)"
    exit 0
fi

# Check if output file is specified, if not, print to stdout
if [[ "$output_file" == "-" ]]; then
    output_file="/dev/stdout"
fi

# Find all files matching the pattern
find . -name "$pattern" | while read file; do
    echo "Processing $file"
    # Print filename to output file
    echo "$file" >> "$output_file"
    pdftotext -f "$first" -l "$last" "$file" tmp_pdf.txt 
    cat tmp_pdf.txt >> "$output_file"
done
