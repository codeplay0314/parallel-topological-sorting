#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <tuple>
#include <vector>

#include <omp.h>
#include <unistd.h>
using namespace std;

int main(const int argc, const char *argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <input>" << std::endl;
        return 1;
    }
    std::string input = argv[1];
    if (input.size() <= 3 || input.substr(input.size() - 3) != ".in") {
        std::cerr << "Error: input file must be a .in file" << std::endl;
        return 1;
    }
    std::string output = input.substr(0, input.rfind('.') + 1) + "out";

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
            printf("%d\n", dep);
        }
    }

    // Topological sort
    std::vector<std::vector<int>> batches; // all "layers"
    std::vector<int> batch;                // next "layer"
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

    return 0;
}
