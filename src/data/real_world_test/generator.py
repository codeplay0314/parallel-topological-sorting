import os
import subprocess
import urllib.request
from collections import defaultdict, deque

# Dataset configuration
datasets = [
    {
        "name": "amazon",
        "url": "https://snap.stanford.edu/data/amazon0302.txt.gz",
        "compressed_file": "amazon0302.txt.gz",
        "decompressed_file": "amazon0302.txt",
        "input_file": "amazon.in",
        "output_file": "amazon.std",
    },
    {
        "name": "epinions",
        "url": "https://snap.stanford.edu/data/soc-Epinions1.txt.gz",
        "compressed_file": "soc-Epinions1.txt.gz",
        "decompressed_file": "soc-Epinions1.txt",
        "input_file": "epinions.in",
        "output_file": "epinions.std",
    },
    {
        "name": "google",
        "url": "https://snap.stanford.edu/data/web-Google.txt.gz",
        "compressed_file": "web-Google.txt.gz",
        "decompressed_file": "web-Google.txt",
        "input_file": "google.in",
        "output_file": "google.std",
    },
    {
        "name": "stanford",
        "url": "https://snap.stanford.edu/data/web-Stanford.txt.gz",
        "compressed_file": "web-Stanford.txt.gz",
        "decompressed_file": "web-Stanford.txt",
        "input_file": "stanford.in",
        "output_file": "stanford.std",
    },
    {
        "name": "wiki",
        "url": "https://snap.stanford.edu/data/wiki-Talk.txt.gz",
        "compressed_file": "wiki-Talk.txt.gz",
        "decompressed_file": "wiki-Talk.txt",
        "input_file": "wiki.in",
        "output_file": "wiki.std",
    }
]

# Utility functions
def download_dataset(url, compressed_file):
    print(f"Downloading {compressed_file}...")
    if not os.path.exists(compressed_file):
        urllib.request.urlretrieve(url, compressed_file)
        print(f"Dataset downloaded and saved as {compressed_file}.")
    else:
        print(f"{compressed_file} already exists. Skipping download.")

def decompress_dataset(compressed_file, decompressed_file):
    print(f"Decompressing {compressed_file}...")
    if not os.path.exists(decompressed_file):
        if compressed_file.endswith(".tar.gz"):
            subprocess.run(["tar", "-xzf", compressed_file], check=True)
        elif compressed_file.endswith(".gz"):
            subprocess.run(["gunzip", "-k", compressed_file], check=True)
        print(f"Decompressed file saved as {decompressed_file}.")
    else:
        print(f"{decompressed_file} already exists. Skipping decompression.")

def convert_to_dot(decompressed_file, dot_file):
    print(f"Converting {decompressed_file} to GraphViz DOT format...")
    with open(decompressed_file, "r") as infile, open(dot_file, "w") as outfile:
        outfile.write("digraph G {\n")
        for line in infile:
            if line.startswith("#"):
                continue  # Skip comment lines
            parts = line.strip().split()
            if len(parts) == 2:
                u, v = parts
                outfile.write(f"    {u} -> {v};\n")
        outfile.write("}\n")
    print(f"Converted to DOT format and saved as {dot_file}.")

def make_acyclic(dot_file, acyclic_file):
    print(f"Making the graph acyclic for {dot_file}...")
    subprocess.run(["acyclic", "-o", acyclic_file, dot_file], check=False)
    print(f"Acyclic graph saved as {acyclic_file}.")

def deduplicate_edges(acyclic_file, deduplicated_file):
    print(f"Deduplicating edges for {acyclic_file}...")
    edge_set = set()
    with open(acyclic_file, "r") as infile:
        lines = infile.readlines()
    with open(deduplicated_file, "w") as outfile:
        outfile.write("digraph G {\n")
        for line in lines:
            if "->" in line:
                u, v = line.strip().replace(";", "").split("->")
                edge = (u, v)
                if edge not in edge_set:
                    edge_set.add(edge)
                    outfile.write(f"    {u} -> {v};\n")
        outfile.write("}\n")
    print(f"Deduplicated edges saved as {deduplicated_file}.")

def generate_input_output(deduplicated_file, input_file, output_file):
    print(f"Generating {input_file} and {output_file}...")
    adj_list = defaultdict(list)
    edges = defaultdict(list)
    with open(deduplicated_file, "r") as f:
        lines = f.readlines()
        for line in lines:
            if "->" in line:
                u, v = line.strip().replace(";", "").split("->")
                u, v = int(u), int(v)
                edges[u].append(v)
                adj_list[v].append(u)

    num_nodes = max(max(adj_list.keys(), default=-1), max(edges.keys(), default=-1)) + 1

    # Topological sort
    def topological_sort(edges, num_nodes):
        in_degree = [0] * num_nodes
        for u in edges:
            for v in edges[u]:
                in_degree[v] += 1

        queue = deque([i for i in range(num_nodes) if in_degree[i] == 0])
        batches = []

        while queue:
            batch = []
            for _ in range(len(queue)):
                node = queue.popleft()
                batch.append(node)
                for neighbor in edges[node]:
                    in_degree[neighbor] -= 1
                    if in_degree[neighbor] == 0:
                        queue.append(neighbor)
            batches.append(batch)

        return batches

    batches = topological_sort(edges, num_nodes)

    # Write .in file
    with open(input_file, "w") as f:
        f.write(f"{num_nodes}\n")
        for i in range(num_nodes):
            neighbors = adj_list.get(i, [])
            f.write(f"{len(neighbors)} " + " ".join(map(str, neighbors)) + "\n")

    # Write .std file
    with open(output_file, "w") as f:
        f.write(f"{len(batches)}\n")
        for batch in batches:
            f.write(f"{len(batch)} " + " ".join(map(str, batch)) + "\n")

    print(f"Generated {input_file} and {output_file} successfully.")

def cleanup_files(*files):
    for file in files:
        if os.path.exists(file):
            os.remove(file)
            print(f"Removed intermediate file: {file}")

# Main workflow
if __name__ == "__main__":
    try:
        # Ensure `acyclic` command is available
        if subprocess.run(["which", "acyclic"], stdout=subprocess.PIPE).returncode != 0:
            print("The `acyclic` command is not available. Install it via `sudo apt install graphviz`.")
            exit(1)

        for dataset in datasets:
            name = dataset["name"]
            url = dataset["url"]
            compressed_file = dataset["compressed_file"]
            decompressed_file = dataset["decompressed_file"]
            input_file = dataset["input_file"]
            output_file = dataset["output_file"]
            dot_file = f"{name}.dot"
            acyclic_file = f"{name}_acyclic.dot"
            deduplicated_file = f"{name}_deduplicated.dot"

            print(f"Processing dataset: {name}")
            download_dataset(url, compressed_file)
            decompress_dataset(compressed_file, decompressed_file)
            convert_to_dot(decompressed_file, dot_file)
            make_acyclic(dot_file, acyclic_file)
            deduplicate_edges(acyclic_file, deduplicated_file)
            generate_input_output(deduplicated_file, input_file, output_file)
            cleanup_files(compressed_file, decompressed_file, dot_file, acyclic_file, deduplicated_file)
            print(f"Completed processing for {name}.\n")
        
        print("All datasets processed successfully!")
    except Exception as e:
        print(f"Error: {e}")