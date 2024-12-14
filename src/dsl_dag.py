import sys
import time

import networkx as nx


class DataLineIn:
    def __init__(self, index, dep_cnt, deps):
        self.index = index
        self.dep_cnt = dep_cnt
        self.deps = deps

    def get_edges(self):
        edges = list()
        for dep in self.deps:
            edges.append((self.index, dep))

        return edges


class TopologicalSort:

    def __init__(self, path):
        self.lines_in = list()
        self.total_lines = 0
        self.graph = nx.DiGraph()
        self.layers = list()
        self.path = path

        print("Starting test for {}".format(self.path))

    @staticmethod
    def timer(func_name, func):
        start = time.time()

        func()

        end = time.time()
        length = (end - start) * 1000
        print("{} completed in {} ms".format(func_name, int(length)))

    def read_lines_in(self):
        line_cnt = 0
        filename = "{}.in".format(self.path)
        with open(filename) as file:
            for line in file:
                line_list_str = line.rstrip().split(" ")
                line_list_int = [int(item) for item in line_list_str]

                if line_cnt == 0:
                    self.total_lines = line_list_int[0]
                else:
                    data_line = DataLineIn(line_cnt - 1, line_list_int[0], line_list_int[1:])
                    self.lines_in.append(data_line)

                line_cnt += 1

    def init(self):
        self.read_lines_in()

        for line in self.lines_in:
            self.graph.add_node(line.index)
            if line.dep_cnt > 0:
                self.graph.add_edges_from(line.get_edges())

    def process(self):

        # print(list(nx.bfs_edges(self.graph, 65535, depth_limit=2)))

        # print(nx.all_pairs_node_connectivity(self.graph, [0, 1, 2]))
        # print(list(nx.ego_graph(self.graph, 0)))
        # print(list(nx.ego_graph(self.graph, 1)))
        # self.graph.remove_nodes_from([0])
        # print(list(nx.ego_graph(self.graph, 1)))
        # print(list(nx.ego_graph(self.graph, 2)))
        # print(list(nx.ego_graph(self.graph, 30000)))

        # print(len(list(nx.lexicographical_topological_sort(self.graph))))
        # print(list(nx.topological_sort(self.graph)))
        # print([sorted(generation) for generation in nx.topological_generations(self.graph)])

        # for layer, nodes in enumerate(nx.topological_generations(self.graph)):
        #     # `multipartite_layout` expects the layer as a node attribute, so add the
        #     # numeric layer value as a node attribute
        #     for node in nodes:
        #         self.graph.nodes[node]["layer"] = layer

        # # Compute the multipartite_layout using the "layer" node attribute
        # pos = nx.multipartite_layout(self.graph, subset_key="layer")

        # fig, ax = plt.subplots()
        # nx.draw_networkx(self.graph, pos=pos, ax=ax)
        # ax.set_title("DAG layout in topological order")
        # fig.tight_layout()
        # plt.show()

        # print(list(nx.topological_generations(self.graph)))

        self.layers = list(nx.topological_generations(self.graph))
        # self.layers = [sorted(generation) for generation in nx.topological_generations(self.graph)]
        # print(len(self.layers))
        self.layers.reverse()

        # while self.graph.number_of_nodes() > 0:
        #     no_dep_nodes = [n for n, d in self.graph.out_degree() if d == 0]
        #     self.graph.remove_nodes_from(no_dep_nodes)
        #     self.layers.append(no_dep_nodes)

    def teardown(self):
        with open("{}.out".format(self.path), "w") as f:
            f.write(str(len(self.layers)) + "\n")
            for layer in self.layers:
                f.write(str(len(layer)) + " ")
                f.write(" ".join(map(str, layer)))
                f.write("\n")


def main():
    tests = sys.argv[1:]
    for test in tests:
        start = time.time()

        topological_sort = TopologicalSort(test)
        topological_sort.timer("Init", topological_sort.init)
        topological_sort.timer("Compute", topological_sort.process)
        topological_sort.timer("Teardown", topological_sort.teardown)

        end = time.time()
        length = (end - start) * 1000
        print("Test completed in {} ms".format(int(length)))


if __name__ == "__main__":
    main()
