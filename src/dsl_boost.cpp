#include <boost/graph/adjacency_list.hpp>
#include <chrono>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

int main() {
    using namespace boost;

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

    // Create a directed graph
    typedef adjacency_list<vecS, vecS, directedS> Graph;
    Graph g;

    // Add some vertices and edges
    add_edge(0, 1, g);
    add_edge(0, 2, g);
    add_edge(1, 2, g);

    // Get the out-degree of vertex 0
    int out_deg = out_degree(0, g);

    std::cout << "Out-degree of vertex 0: " << out_deg << std::endl;

    return 0;
}