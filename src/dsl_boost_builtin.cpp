
#include <algorithm>
#include <boost/config.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/topological_sort.hpp>
#include <chrono>
#include <fstream>
#include <iostream>
#include <iterator>
#include <list>
#include <string>
#include <utility>
#include <vector>

#include <omp.h>

using namespace boost;

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

    // Create a directed graph
    typedef adjacency_list<vecS, vecS, directedS, vertex_color_t, default_color_type> Graph;
    typedef boost::graph_traits<Graph>::vertex_descriptor Vertex;

    Graph g;

    int n;
    ifs >> n;
    std::vector<std::vector<int>> adj(n);
    std::vector<int> indeg(n);

    std::vector<Graph::vertex_descriptor> vertex_des(n);
    std::vector<std::vector<int>> raw_deps(n);

    // Load edges only (this method does not expect vertices)
    for (int i = 0, dep_cnt; i < n; ++i) {
        ifs >> dep_cnt;

        for (int j = 0, dep; j < dep_cnt; ++j) {
            ifs >> dep;
            add_edge(i, dep, g);
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

    // Perform topological
    typedef std::vector<Vertex> container;
    container c;
    topological_sort(g, std::back_inserter(c));

    // Write result in reverse order
    boost::property_map<Graph, vertex_index_t>::type id = get(vertex_index, g);
    for (container::reverse_iterator ii = c.rbegin(); ii != c.rend(); ++ii)
        ofs << id[*ii] << " ";
    ofs << std::endl;

    // End measuring computation time
    auto end_comp = std::chrono::high_resolution_clock::now();
    auto comp_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_comp - start_comp).count();

    ifs.close();
    ofs.close();

    // Print initialization and computation times
    std::cout << "Initialization time: " << init_time << " ms" << std::endl;
    std::cout << "Computation time: " << comp_time << " ms" << std::endl;

    return 0;
}
