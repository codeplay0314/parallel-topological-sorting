#include <chrono>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

int main(const int argc, const char *argv[]) {
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

    // Read the graph
    int n;
    ifs >> n;
    std::vector<std::vector<int>> adj(n);
    std::vector<int> indeg(n);
    for (int i = 0; i < n; ++i) {
        ifs >> indeg[i];
        for (int j = 0, dep; j < indeg[i]; ++j) {
            ifs >> dep;
            adj[dep].push_back(i);
        }
    }

    // End measuring initialization time
    auto end_init = std::chrono::high_resolution_clock::now();
    auto init_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_init - start_init).count();

    // Start measuring computation time
    auto start_comp = std::chrono::high_resolution_clock::now();

    // Topological sort
    std::vector<std::vector<int>> batches;
    std::vector<int> batch;
    for (int i = 0; i < n; ++i) {
        if (indeg[i] == 0) {
            batch.push_back(i);
        }
    }
    while (!batch.empty()) {
        batches.push_back(batch);
        std::vector<int> next_batch;
        for (int i : batch) {
            for (int j : adj[i]) {
                if (--indeg[j] == 0) {
                    next_batch.push_back(j);
                }
            }
        }
        batch = std::move(next_batch);
    }

    // End measuring computation time
    auto end_comp = std::chrono::high_resolution_clock::now();
    auto comp_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_comp - start_comp).count();

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

    // Print initialization and computation times
    std::cout << "Initialization time: " << init_time << " ms" << std::endl;
    std::cout << "Computation time: " << comp_time << " ms" << std::endl;

    return 0;
}
