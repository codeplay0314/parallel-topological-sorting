# Parallel Topological Sorting

This repository provides implementations and experimentation scripts for parallel topological sorting on large Directed Acyclic Graphs (DAGs). We explore several approaches, including a traditional serial algorithm, a CUDA-based parallel implementation, and DSL-based implementations using both NetworkX (Python) and Boost (C++).

## Overview

Topological sorting is a fundamental problem for ordering tasks or dependencies in a DAG. Here, we focus on evaluating performance and scalability across various input sizes and graph structures. This includes:
- **Serial Implementation** for a baseline comparison.
- **CUDA Implementation** to leverage GPU parallelism.
- **DSL Implementations** (NetworkX, Boost) to examine performance on high-level graph libraries.

We provide synthetic dataset generators, real-world graph conversions, correctness checkers, and automated test scripts to streamline the entire evaluation process.

## Repository Structure

```plaintext
src
├── test.sh                 # Automation test script: runs tests across all implementations and datasets
├── serial.cpp              # Serial implementation of topological sorting (Kahn’s algorithm)
├── cuda.cu                 # CUDA implementation of topological sorting for parallel speedups
├── dsl_networkx_builtin.py # DSL-based (NetworkX) Python implementation that uses builtin topological sort algorithm
├── dsl_networkx_kahn.py    # DSL-based (NetworkX) Python implementation that uses custom Kahn's Algorithm
├── dsl_boost_builtin.cpp   # DSL-based (Boost Graph Library) C++ implementation that builtin topological sort algorithm
├── dsl_boost_kahn.cpp      # DSL-based (Boost Graph Library) C++ implementation that uses custom Kahn's Algorithm
├── psc-run-cpu.sh          # Shell script to run all cpu-based tests on PSC machines
├── psc-run-gpu.sh          # Shell script to run all gpu-based tests on PSC machines
└── data
    ├── generate.sh      # Script to automatically generate all test datasets
    ├── node_test
    │   ├── generator.py # Generates Node Test dataset (varying node counts)
    ├── edge_test
    │   ├── generator.py # Generates Edge Test dataset (varying edge counts)
    ├── depth_test
    │   ├── generator.py # Generates Depth Test dataset (varying graph depths)
    ├── real_world_test
    │   ├── generator.py # Generates Real-World Test dataset from SNAP data
    └── checker.py       # Checks correctness of outputs against standard solutions
```

### Implementations

- **`serial.cpp`**: Implements a standard topological sort (Kahn's algorithm) as a baseline.
- **`cuda.cu`**: Parallelizes key steps of topological sorting on GPUs using CUDA. Ideal for large, wide graphs.
- **`dsl_networkx_builtin.py`**: Uses Python's NetworkX library as a DSL to implement topological sorting via the builtin topological sort algorithm.
- **`dsl_networkx_kahn.py`**: Uses Python's NetworkX library as a DSL to implement topological sorting via Kahn's Algorithm.
- **`dsl_boost_builtin.cpp`**: Employs the Boost Graph Library in C++ as a DSL solution, allowing for a high-level yet performant approach via the builtin topological sort algorithm.
- **`dsl_boost_kahn.cpp`**: Employs the Boost Graph Library in C++ as a DSL solution, allowing for a high-level yet performant approach via Kahn's Algorithm.

### Data Generation and Tests

- **`generate.sh`**: Automates the generation of all synthetic datasets used in the experiments.
- **`checker.py`**: Validates the correctness of each implementation’s output against known solutions.
  
**Dataset Generators:**
- **`node_test/generator.py`**: Creates datasets where the number of nodes varies, while edges remain fixed.
- **`edge_test/generator.py`**: Produces datasets where the number of edges varies, with node count fixed.
- **`depth_test/generator.py`**: Generates datasets controlling the depth of the graph.
- **`real_world_test/generator.py`**: Processes and transforms real-world datasets (from SNAP) into `.in` files for testing.

### Test Script

- **`test.sh`**: Runs end-to-end tests for all implementations and datasets. It compiles the code, executes topological sorting with each method, and uses `checker.py` to verify correctness. Time measurements are taken for performance comparisons.
- **`psc-run-cpu.sh`**: Automates runnign CPU based tests on PSC machines.
- **`psc-run-gpu.sh`**: Automates runnign GPU based tests on PSC machines.

## Getting Started

1. **Clone the repository**:
```bash
git clone https://github.com/codeplay0314/parallel-topological-sorting.git
cd parallel-topological-sorting/src
```

2. **Generate Data**:
```
cd data
./generate.sh
```

3. **Compile and Run**:
```
# For Serial
g++ -o serial_ts serial.cpp
./serial_ts input.in output.out

# For CUDA
nvcc -o cuda_ts cuda.cu
./cuda_ts input.in output.out
```

4. **Run Tests**:
```
./test.sh
```