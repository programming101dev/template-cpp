#!/usr/bin/env bash

# Default values
dest_dir=""

# Function to display usage information
usage()
{
    echo "Usage: $0 <destination_directory>"
    exit 1
}

# Check if exactly one argument is provided
if [ "$#" -ne 1 ]; then
    usage
fi

dest_dir=$1

# Construct the source directory path
source_dir="."

# Check if the destination directory exists; if not, create it
if [ ! -d "$dest_dir" ]; then
    mkdir -p "$dest_dir"
    echo "Created destination directory: $dest_dir"
fi

# Copy the sanitizers file
sanitizers_file="sanitizers.txt"

if [ -e "$source_dir/$sanitizers_file" ]; then
    cp -a "$source_dir/$sanitizers_file" "$dest_dir"
    echo "Copied $sanitizers_file to $dest_dir"
else
    echo "$sanitizers_file not found in the template directory. Skipping."
fi

# Copy the supported compilers file
compilers_file="supported_cxx_compilers.txt"

if [ -e "$source_dir/$compilers_file" ]; then
    cp -a "$source_dir/$compilers_file" "$dest_dir"
    echo "Copied $compilers_file to $dest_dir"
else
    echo "$compilers_file not found in the template directory. Skipping."
fi

# List of files and directories to copy
files_to_copy=(".flags" ".clang-format" ".gitignore" "build.sh" "build-all.sh" "change-compiler.sh" "check-compilers.sh" "check-env.sh" "move.sh" "files.txt" "generate-cmakelists.sh" "generate-flags.sh" "link-flags.sh" "README.md" "src" "include")

# Copy files and directories to the destination directory
for item in "${files_to_copy[@]}"; do
    source_item="$source_dir/$item"
    dest_item="$dest_dir/$item"

    if [ -e "$source_item" ]; then
        if [ ! -e "$dest_item" ]; then
            cp -a "$source_item" "$dest_item"
            echo "Copied $item to $dest_dir"
        else
            echo "$item already exists in $dest_dir. Skipping."
        fi
    else
        echo "$item not found in the template directory. Skipping."
    fi
done

echo "Copy operation complete."

# Navigate to the destination directory
pushd "$dest_dir" || exit

# Check if .flags exists and run scripts if it doesn't
if [ ! -e ".flags" ]; then
    echo "Running check-compilers.sh and generate-flags.sh scripts."
    ./check-compilers.sh
    ./generate-flags.sh
else
    echo ".flags file already exists."
fi

# Return to the original directory
popd || exit
