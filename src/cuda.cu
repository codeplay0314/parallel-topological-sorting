#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/copy.h>
#include <thrust/scan.h>
#include <thrust/fill.h>
#include <thrust/sequence.h>
#include <thrust/reduce.h>
#include <thrust/for_each.h>
#include <thrust/execution_policy.h>
#include <thrust/iterator/counting_iterator.h>
#include <cuda_runtime.h>
#include <chrono>
#include <iostream>
#include <vector>
#include <fstream>
#include <algorithm>

__global__ void findZeroInDegreeNodes(const int *inDegrees, int *flags, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        flags[i] = (inDegrees[i] == 0) ? 1 : 0;
    }
}

__global__ void markProcessedNodes(int *inDegrees, const int *zeroNodes, int count) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < count) {
        inDegrees[zeroNodes[i]] = -1;
    }
}

__global__ void reduceInDegree(int *inDegrees, const int *edges, const int *rowPtr, const int *zeroNodes, int count) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < count) {
        int node = zeroNodes[i];
        for (int e = rowPtr[node]; e < rowPtr[node+1]; e++) {
            atomicSub(&inDegrees[edges[e]], 1);
        }
    }
}

// Functor to scatter zero-degree nodes
struct ScatterFunctor {
    int *d_flags;
    int *d_positions;
    int *d_zeroNodes;

    __host__ __device__
    ScatterFunctor(int *flags, int *positions, int *zeroNodes)
        : d_flags(flags), d_positions(positions), d_zeroNodes(zeroNodes) {}

    __host__ __device__
    void operator()(int idx) {
        if (d_flags[idx] == 1) {
            int pos = d_positions[idx];
            d_zeroNodes[pos] = idx;
        }
    }
};

int main(int argc, char **argv) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <input>" << std::endl;
        return 1;
    }
    std::string input = argv[1];
    if (input.size() <= 3 || input.substr(input.size() - 3) != ".in") {
        std::cerr << "Error: input file must be a .in file" << std::endl;
        return 1;
    }
    std::string output = argv[2];
    if (output.size() <= 4 || output.substr(input.size() - 3) != ".out") {
        std::cerr << "Error: output file must be a .out file" << std::endl;
        return 1;
    }

    std::ifstream ifs(input);
    if (!ifs) {
        std::cerr << "Error: cannot open file " << input << std::endl;
        return 1;
    }
    std::ofstream ofs(output);
    if (!ofs) {
        ifs.close();
        std::cerr << "Error: cannot open file " << output << std::endl;
        return 1;
    }

    // Start measuring initialization time
    auto start_init = std::chrono::high_resolution_clock::now();

    int n;
    ifs >> n;

    std::vector<int> rowPtrHost(n+1, 0);
    std::vector<int> inDegreeHost(n, 0);
    std::vector<std::vector<int>> adj(n);

    // Reading the graph
    for (int i = 0; i < n; i++) {
        ifs >> inDegreeHost[i];
        for (int j = 0, dep; j < inDegreeHost[i]; j++) {
            ifs >> dep;
            adj[dep].push_back(i);
        }
    }

    for (int i = 0; i < n; i++) {
        rowPtrHost[i+1] = (int)(rowPtrHost[i] + adj[i].size());
    }

    int m = rowPtrHost[n];
    std::vector<int> edgesHost(m);
    for (int i = 0; i < n; i++) {
        std::copy(adj[i].begin(), adj[i].end(), edgesHost.begin() + rowPtrHost[i]);
    }

    int *d_inDegrees, *d_rowPtr, *d_edges;
    cudaMalloc(&d_inDegrees, n * sizeof(int));
    cudaMalloc(&d_rowPtr, (n+1) * sizeof(int));
    cudaMalloc(&d_edges, m * sizeof(int));

    cudaMemcpy(d_inDegrees, inDegreeHost.data(), n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_rowPtr, rowPtrHost.data(), (n+1) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_edges, edgesHost.data(), m * sizeof(int), cudaMemcpyHostToDevice);

    thrust::device_vector<int> flags(n, 0);
    thrust::device_vector<int> zeroNodes(n);

    int remaining = n;
    const int blockSize = 1024;

    std::vector<std::vector<int>> batches;
    
    // End measuring initialization time
    auto end_init = std::chrono::high_resolution_clock::now();
    auto init_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_init - start_init).count();

    // Start measuring computation time
    auto start_comp = std::chrono::high_resolution_clock::now();

    while (remaining > 0) {
        // Find zero in-degree nodes for this iteration
        int gridSize = (n + blockSize - 1)/ blockSize;
        findZeroInDegreeNodes<<<gridSize, blockSize>>>(d_inDegrees, thrust::raw_pointer_cast(flags.data()), n);
        cudaDeviceSynchronize();

        int count = thrust::reduce(flags.begin(), flags.end());
        if (count == 0) {
            // No zero-degree nodes, cycle found
            std::cerr << "Error: cycle found\n";
            return 1;
        }

        // Compute positions via prefix sum for scattering zero-degree nodes
        thrust::device_vector<int> positions(n);
        thrust::exclusive_scan(flags.begin(), flags.end(), positions.begin());

        int *d_flags = thrust::raw_pointer_cast(flags.data());
        int *d_positions = thrust::raw_pointer_cast(positions.data());
        int *d_zeroNodes = thrust::raw_pointer_cast(zeroNodes.data());

        // Scatter indices of zero-degree nodes
        thrust::for_each(thrust::device, thrust::counting_iterator<int>(0), thrust::counting_iterator<int>(n),
                         ScatterFunctor(d_flags, d_positions, d_zeroNodes));

        // Copy the current batch from device to host
        std::vector<int> hostBatch(count);
        thrust::copy_n(zeroNodes.begin(), count, hostBatch.begin());
        batches.push_back(hostBatch);

        // Mark processed nodes
        gridSize = (count + blockSize - 1) / blockSize;
        markProcessedNodes<<<gridSize, blockSize>>>(d_inDegrees, thrust::raw_pointer_cast(zeroNodes.data()), count);
        cudaDeviceSynchronize();

        // Reduce in-degree of their neighbors
        gridSize = (count + blockSize - 1) / blockSize;
        reduceInDegree<<<gridSize, blockSize>>>(d_inDegrees, d_edges, d_rowPtr, thrust::raw_pointer_cast(zeroNodes.data()), count);
        cudaDeviceSynchronize();

        remaining -= count;

        // Reset flags for next iteration
        thrust::fill(flags.begin(), flags.end(), 0);
    }

    // End measuring computation time
    auto end_comp = std::chrono::high_resolution_clock::now();
    auto comp_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_comp - start_comp).count();

    ofs << batches.size() << "\n";
    for (auto &batch : batches) {
        ofs << batch.size();
        for (int node : batch) {
            ofs << " " << node;
        }
        ofs << "\n";
    }

    cudaFree(d_inDegrees);
    cudaFree(d_rowPtr);
    cudaFree(d_edges);

    // Print initialization and computation times
    std::cout << "Initialization time: " << init_time << " ms" << std::endl;
    std::cout << "Computation time: " << comp_time << " ms" << std::endl;

    return 0;
}