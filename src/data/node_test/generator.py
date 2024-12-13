import os
import random
from collections import defaultdict, deque


def generate_dag(num_nodes, num_edges):
    # Generate a random DAG with nodes indexed from 0
    edges = set()
    while len(edges) < num_edges:
        u = random.randint(0, num_nodes - 1)
        v = random.randint(0, num_nodes - 1)
        if u != v and (u, v) not in edges and u < v:
            edges.add((u, v))
    
    # Ensure edges form a valid DAG
    new_edges = {i: [] for i in range(num_nodes)}
    adj_list = defaultdict(list)
    for u, v in edges:
        adj_list[v].append(u)
        new_edges[u].append(v)
    
    return adj_list, new_edges


def topological_sort(edges, num_nodes):
    # Perform topological sort and generate batches
    in_degree = [0] * num_nodes
    for u in edges:
        for v in edges[u]:
            in_degree[v] += 1

    queue = deque([i for i in range(num_nodes) if in_degree[i] == 0])
    topo_order = []
    batches = []

    while queue:
        batch = []
        for _ in range(len(queue)):
            node = queue.popleft()
            topo_order.append(node)
            batch.append(node)
            for neighbor in edges[node]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)
        batches.append(batch)

    return topo_order, batches


def write_files(index, num_nodes, adj_list, batches):
    # Write the input file
    input_file = f"{index}.in"
    with open(input_file, "w") as f:
        f.write(f"{num_nodes}\n")
        for i in range(num_nodes):
            neighbors = adj_list.get(i, [])
            f.write(f"{len(neighbors)} " + " ".join(map(str, neighbors)) + "\n")

    # Write the output file
    output_file = f"{index}.std"
    with open(output_file, "w") as f:
        # Write the number of batches
        f.write(f"{len(batches)}\n")
        
        # Write each batch
        for batch in batches:
            f.write(f"{len(batch)} " + " ".join(map(str, batch)) + "\n")


if __name__ == "__main__":
    
    random.seed(15618)

    # Define the parameters for the five test cases
    test_cases = [
        (10**3, 10**5),
        (10**4, 10**5),
        (10**5, 10**5),
        (10**6, 10**5),
        (10**7, 10**5),
    ]

    for index, (num_nodes, num_edges) in enumerate(test_cases, start=1):
        print(f"Generating test case {index} with {num_nodes} nodes and {num_edges} edges...")
        adj_list, edges = generate_dag(num_nodes, num_edges)
        _, batches = topological_sort(edges, num_nodes)
        write_files(index, num_nodes, adj_list, batches)
        print(f"Test case {index} generated successfully!")