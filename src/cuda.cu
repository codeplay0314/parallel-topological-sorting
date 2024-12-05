#include <fstream>
#include <iostream>
#include <string>
#include <vector>

struct GlobalConstants {
    int n;
    int pow2n;
} params;

__constant__ GlobalConstants cuParams;

__global__ void kernelCountDependency(int *ifNoDependencyArray, int *dependencyPrefixSum) {

    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if (i >= cuParams.n) {
        return;
    }

    ifNoDependencyArray[i] = (dependencyPrefixSum[i * cuParams.pow2n + cuParams.n + 1] == 0);
}

__global__ void kernelXor(int *a, int *b, int size) {

    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if (i < size) {
        a[i] ^= b[i];
    }
}

__global__ void kernelClearDependencies(int *dependencyMatrix, int *independentIndices, int cnt) {

    int x = blockIdx.x * blockDim.x + threadIdx.x;

    if (x >= cnt * cuParams.n) {
        return;
    }

    int i = x % cuParams.n;
    int j = independentIndices[x / cuParams.n];

    dependencyMatrix[i * cuParams.pow2n + j] = 0;
}

/* Helper function to round up to a power of 2.
 */
static inline int nextPow2(int n) {
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n++;
    return n;
}

/**
* Helper function to print array on device
*/
void print_device_array(int *device_data, size_t length) {
    static int limit = 256;
    printf("[ ");
    if (length <= 2 * limit) {
        for (int i = 0, x; i < length; i++) {
            cudaMemcpy(&x, &device_data[i], sizeof(int), cudaMemcpyDeviceToHost);
            printf("%d ", x);
        }
    } else {
        for (int i = 0, x; i < limit; i++) {
            cudaMemcpy(&x, &device_data[i], sizeof(int), cudaMemcpyDeviceToHost);
            printf("%d ", x);
        }
        printf("... ");
        for (int i = 0, x; i < limit; i++) {
            cudaMemcpy(&x, &device_data[length - limit + i - 1], sizeof(int), cudaMemcpyDeviceToHost);
            printf("%d ", x);
        }
    }
    printf("]\n");
}

__global__ void upsweep_kernel(int *data, int length, int st_scale, int ed_scale) {
    extern __shared__ int sh_data[];

    unsigned int t = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int index = (t * st_scale + st_scale) * 2 - 1;
    unsigned int i = threadIdx.x * 2 + 1;

    sh_data[i - 1] = data[index - st_scale];
    sh_data[i] = data[index];
    __syncthreads();

    for (int scale = st_scale; scale < ed_scale; scale *= 2) {
        if ((t + 1) % (scale / st_scale) == 0) {
            sh_data[i] += sh_data[i - (scale / st_scale)];
        }
        __syncthreads();
    }

    data[index - st_scale] = sh_data[i - 1];
    data[index] = sh_data[i];
}

__global__ void downsweep_kernel(int *data, int length, int st_scale, int ed_scale) {
    extern __shared__ int sh_data[];

    unsigned int t = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int index = (t * ed_scale + ed_scale) * 2 - 1;
    unsigned int i = threadIdx.x * 2 + 1;

    sh_data[i - 1] = data[index - ed_scale];
    sh_data[i] = data[index];
    __syncthreads();

    for (int scale = st_scale / ed_scale / 2; scale >= 1; scale /= 2) {
        if ((t + 1) % scale == 0) {
            int x = sh_data[i - scale];
            sh_data[i - scale] = sh_data[i];
            sh_data[i] += x;
        }
        __syncthreads();
    }

    data[index - ed_scale] = sh_data[i - 1];
    data[index] = sh_data[i];
}

void exclusive_scan(int *device_data, int length) {

    static const int maxThreadNum = 1024;

    length = nextPow2(length);

    std::vector<std::vector<int>> params;

    for (int st_scale = 1; st_scale < length; st_scale *= maxThreadNum * 2) {
        int ed_scale = min(st_scale * maxThreadNum * 2, length);
        int threadsPerBlock = min(maxThreadNum, length / st_scale / 2);
        int numBlocks = max(1, length / (threadsPerBlock * st_scale * 2));
        int sharedMemorySize = threadsPerBlock * 2 * sizeof(int);
        upsweep_kernel<<<numBlocks, threadsPerBlock, sharedMemorySize>>>(device_data, length, st_scale, ed_scale);
        params.push_back(std::vector<int>{st_scale, ed_scale, threadsPerBlock, numBlocks});
        cudaDeviceSynchronize();
    }

    int zero = 0;
    cudaMemcpy(device_data + length - 1, &zero, sizeof(int), cudaMemcpyHostToDevice);

    for (int i = params.size() - 1; i >= 0; i--) {
        int st_scale = params[i][1];
        int ed_scale = params[i][0];
        int threadsPerBlock = params[i][2];
        int numBlocks = params[i][3];
        int sharedMemorySize = threadsPerBlock * 2 * sizeof(int);
        downsweep_kernel<<<numBlocks, threadsPerBlock, sharedMemorySize>>>(device_data, length, st_scale, ed_scale);
        cudaDeviceSynchronize();
    }
}

__global__ void kernel_set_output(int *output, int *input, int length) {

    int i = blockIdx.x * blockDim.x + threadIdx.x;

    // Set output to 0 if past length
    if (i < length - 1) {
        int val = input[i];
        int above = input[i + 1];

        if (val != above) {
            output[val] = i;
        }
    }
}

int main(const int argc, const char *argv[]) {

    static const size_t maxThreadsPerBlock = 1024;

    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <input>" << std::endl;
        return 1;
    }
    std::string input = argv[1];
    if (input.size() <= 3 || input.substr(input.size() - 3) != ".in") {
        std::cerr << "Error: input file must be a .in file" << std::endl;
        return 1;
    }
    std::string output  = input.substr(0, input.rfind('.') + 1) + "out";

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
    
    std::vector<std::vector<int>> batches;
    std::vector<int> batch;

    // Read the graph
    ifs >> params.n;
    params.pow2n = nextPow2(params.n + 1);
    cudaMemcpyToSymbol(cuParams, &params, sizeof(GlobalConstants));

    size_t dependencyMatrixLength = params.pow2n * params.n;
    size_t dependencyMatrixSize = dependencyMatrixLength * sizeof(int);

    std::vector<int> depMatrix(dependencyMatrixLength, 0);
    for (int i = 0, m; i < params.n; ++i) {
        ifs >> m;
        for (int j = 0, dep; j < m; ++j) {
            ifs >> dep;
            depMatrix[i * params.pow2n + dep] = 1;
        }
    }

    int *d_dependencyMatrix;
    cudaMalloc(&d_dependencyMatrix, dependencyMatrixSize);
    cudaMemcpy(d_dependencyMatrix, depMatrix.data(), dependencyMatrixSize, cudaMemcpyHostToDevice);

    int *d_ifNoDependencyArray;
    cudaMalloc(&d_ifNoDependencyArray, params.pow2n * sizeof(int));

    int *d_ifSortedArray;
    cudaMalloc(&d_ifSortedArray, params.n * sizeof(int));
    cudaMemset(d_ifSortedArray, 0, params.n * sizeof(int));

    int *d_dependencyPrefixSum;
    cudaMalloc(&d_dependencyPrefixSum, dependencyMatrixSize);

    int *d_independentIndices;
    cudaMalloc(&d_independentIndices, (params.n + 1) * sizeof(int));

    int circles_left = params.n;
    while (circles_left > 0) {
        cudaMemcpy(d_dependencyPrefixSum, d_dependencyMatrix, dependencyMatrixSize, cudaMemcpyDeviceToDevice);
        for (int i = 0; i < params.n; i++) {
            exclusive_scan(d_dependencyPrefixSum + i * params.pow2n, params.n + 1);
        }

        int threadsPerBlock = std::min(maxThreadsPerBlock, static_cast<size_t>(params.n));
        int numBlocks = (params.n + threadsPerBlock - 1) / threadsPerBlock;
        kernelCountDependency<<<numBlocks, threadsPerBlock>>>(d_ifNoDependencyArray, d_dependencyPrefixSum);
        cudaDeviceSynchronize();

        // Exclude circles already sorted
        kernelXor<<<numBlocks, threadsPerBlock>>>(d_ifNoDependencyArray, d_ifSortedArray, params.n);
        cudaDeviceSynchronize();
        kernelXor<<<numBlocks, threadsPerBlock>>>(d_ifSortedArray, d_ifNoDependencyArray, params.n);
        cudaDeviceSynchronize();

        exclusive_scan(d_ifNoDependencyArray, params.n + 1);

        kernel_set_output<<<numBlocks, threadsPerBlock>>>(d_independentIndices, d_ifNoDependencyArray, params.n + 1);

        size_t cnt = 0;
        cudaMemcpy(&cnt, d_ifNoDependencyArray + params.n, sizeof(int), cudaMemcpyDeviceToHost);
        cudaDeviceSynchronize();

        if (cnt == 0) {
            std::cerr << "Error: cycle found" << std::endl;
            return 1;
        }

        batch = std::vector<int>(cnt);
        cudaMemcpy(batch.data(), d_independentIndices, cnt * sizeof(int), cudaMemcpyDeviceToHost);
        batches.push_back(batch);

        // Clear dependencies
        threadsPerBlock = std::min(maxThreadsPerBlock, cnt * params.n);
        numBlocks = (cnt * params.n + threadsPerBlock - 1) / threadsPerBlock;
        kernelClearDependencies<<<numBlocks, threadsPerBlock>>>(d_dependencyMatrix, d_independentIndices, cnt);
        cudaDeviceSynchronize();

        circles_left -= cnt;
    }

    // Write the result
    ofs << batches.size() << std::endl;
    for (const auto &batch : batches) {
        ofs << batch.size();
        for (int i : batch) {
            ofs << ' ' << i;
        }
        ofs << std::endl;
    }

    ifs.close();
    ofs.close();

    // Free allocated memory
    cudaFree(d_dependencyMatrix);
    cudaFree(d_ifNoDependencyArray);
    cudaFree(d_ifSortedArray);
    cudaFree(d_dependencyPrefixSum);
    cudaFree(d_independentIndices);

    return 0;
}