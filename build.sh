#!/usr/bin/env bash

CC=""

# Function to display usage information
usage() {
    echo "Usage: $0 -c <compiler>"
    exit 1
}

# Parse command-line options
while getopts "c:" opt; do
    case $opt in
        c)
            CC="$OPTARG"
            ;;
        *)
            usage
            ;;
    esac
done

# Check if CC is empty
if [ -z "$CC" ]; then
    usage
fi

# Set the CC environment variable to the specified compiler
export CC="$CC"

# Run the cleanup.sh script
"./cleanup.sh"

# Run the generate-makefile.sh script
"./generate-makefiles.sh"

# Run the run-makefiles.sh script
make clean all

# Optionally, you can unset the CC environment variable
unset CC
