#include <boost/graph/adjacency_list.hpp>
#include <chrono>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include <omp.h>

using namespace boost;

struct Vertex {
    int32_t id;
    std::vector<int> in_deps;
};

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

    // Create a directed graph - don't use vecS to avoid slow(er) clear_in_edges times
    typedef adjacency_list<listS, listS, bidirectionalS, Vertex> Graph;
    Graph g;

    int n;
    ifs >> n;
    std::vector<std::vector<int>> adj(n);
    std::vector<int> indeg(n);

    std::vector<Graph::vertex_descriptor> vertex_des(n);
    std::vector<std::vector<int>> raw_deps(n);

    // Load vertices
    for (int i = 0; i < n; ++i) {
        ifs >> indeg[i];
        vertex_des[i] = add_vertex(g);
        g[vertex_des[i]].id = i;

        for (int j = 0, dep; j < indeg[i]; ++j) {
            ifs >> dep;
            raw_deps[i].push_back(dep);
        }
    }

    // Load edges (do this in two steps to avoid adding edges to nodes that haven't been created yet)
    for (int i = 0; i < n; ++i) {
        std::vector<int> deps = raw_deps[i];

        for (int j = 0, dep; j < deps.size(); ++j) {
            dep = deps[j];
            add_edge(vertex_des[i], vertex_des[dep], g);
        }
    }

    std::cout << "Num vertices: " << num_vertices(g) << std::endl;
    std::cout << "Num edges: " << num_edges(g) << std::endl;

    // End measuring initialization time
    auto end_init = std::chrono::high_resolution_clock::now();
    auto init_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_init - start_init).count();

    // Start measuring computation time
    auto start_comp = std::chrono::high_resolution_clock::now();

    typedef graph_traits<Graph>::vertex_descriptor VertexDes;
    typedef graph_traits<Graph>::vertex_iterator VertexIter;

    Graph::vertex_iterator v, vend;

    // Sort all vertices into batches
    std::vector<std::vector<int>> batches;
    int remaining_vertices = num_vertices(g);
    while (remaining_vertices > 0) {

        std::vector<Graph::vertex_iterator> vi_list(remaining_vertices);

        // std::cout << "remaining_vertices: " << remaining_vertices << std::endl;
        std::vector<int> batch;

        int i = 0;
        for (tie(v, vend) = vertices(g); v != vend; v++) {
            vi_list[i] = v;
            i++;
        }

        // Step 1. Find all 0 degree nodes
#pragma omp parallel
        {

            std::vector<int> local_batch;

            // Per-thread: find 0 degree nodes
#pragma omp loop
            for (int i = 0; i < remaining_vertices; i++) {
                int out_deg = out_degree(*vi_list[i], g);
                if (out_deg == 0) {
                    local_batch.push_back(g[*vi_list[i]].id);
                }
            }

            // Merge findings
#pragma omp critical
            { batch.insert(batch.end(), local_batch.begin(), local_batch.end()); }
        }

        // Step 2. Remove 0 degree nodes
        for (int i = 0; i < batch.size(); i++) {
            int batch_id = batch[i];
            clear_in_edges(vertex_des[batch_id], g);
            remove_vertex(vertex_des[batch_id], g);
        }

        reverse(batch.begin(), batch.end());

        batches.push_back(batch);
        remaining_vertices -= batch.size();
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
