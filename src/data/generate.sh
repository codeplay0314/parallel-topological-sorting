#!/bin/bash

# Directories to run the generator script
directories=("depth_test" "edge_test" "node_test")

# Iterate through each directory
for dir in "${directories[@]}"; do
    echo "Processing directory: $dir"

    # Navigate to the directory
    if [ -d "$dir" ]; then
        cd "$dir" || { echo "Failed to enter directory $dir"; exit 1; }
        
        # Run the Python script and check for errors
        if [ -f "generator.py" ]; then
            echo "Running generator.py in $dir..."
            python3 generator.py
            if [ $? -eq 0 ]; then
                echo "Successfully generated files in $dir"
            else
                echo "Error occurred while running generator.py in $dir"
                exit 1
            fi
        else
            echo "generator.py not found in $dir"
            exit 1
        fi

        # Return to the original directory
        cd - > /dev/null || exit
    else
        echo "Directory $dir does not exist"
        exit 1
    fi
done

echo "All directories processed successfully!"