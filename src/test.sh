#!/bin/bash

# Compile the C++ program
echo "Compiling serial.cpp..."
g++ serial.cpp -o serial_ts
if [ $? -ne 0 ]; then
    echo "Compilation of serial.cpp failed. Exiting."
    exit 1
fi
echo "Compilation of serial.cpp successful."

# Compile the CUDA program
echo "Compiling cuda.cu..."
nvcc cuda.cu -o cuda_ts
if [ $? -ne 0 ]; then
    echo "Compilation of cuda.cu failed. Exiting."
    exit 1
fi
echo "Compilation of cuda.cu successful."

# Directories to test
datasets=("node_test" "edge_test" "depth_test" "real_world_test")

# Process each dataset directory
for dataset in "${datasets[@]}"; do
    echo "Processing dataset: $dataset"

    # Find all .in files in the dataset directory
    input_files=$(find "data/$dataset" -type f -name "*.in")

    # Process each test file
    for input_file in $input_files; do
        test_name=$(basename "$input_file" .in)
        output_file="data/$dataset/$test_name.out"

        # Run the serial program
        echo "Running serial_ts on $input_file -> $output_file"
        ./serial_ts "$input_file" "$output_file"
        if [ $? -ne 0 ]; then
            echo "Error running serial_ts on $input_file. Aborting."
            exit 1
        fi

        # Run the Python checker for serial output
        echo "Running checker for serial output: $input_file..."
        python3 data/checker.py "data/$dataset/$test_name"
        if [ $? -ne 0 ]; then
            echo "Checker script failed for serial output of $input_file. Aborting."
            exit 1
        fi
        last_line_serial=$(python3 data/checker.py "data/$dataset/$test_name" | tail -n 1)
        if [[ "$last_line_serial" != "Test data/$dataset/$test_name passed" ]]; then
            echo "Serial test failed for $input_file. Aborting."
            exit 1
        fi

        # Run the CUDA program
        echo "Running cuda_ts on $input_file -> $output_file"
        ./cuda_ts "$input_file" "$output_file"
        if [ $? -ne 0 ]; then
            echo "Error running cuda_ts on $input_file. Aborting."
            exit 1
        fi

        # Run the Python checker for CUDA output
        echo "Running checker for CUDA output: $input_file..."
        python3 data/checker.py "data/$dataset/$test_name"
        if [ $? -ne 0 ]; then
            echo "Checker script failed for CUDA output of $input_file. Aborting."
            exit 1
        fi
        last_line_cuda=$(python3 data/checker.py "data/$dataset/$test_name" | tail -n 1)
        if [[ "$last_line_cuda" != "Test data/$dataset/$test_name passed" ]]; then
            echo "CUDA test failed for $input_file. Aborting."
            exit 1
        fi

        echo "Test $input_file passed for both serial and CUDA implementations."
    done
done

echo "All tests passed successfully for both serial and CUDA implementations!"
