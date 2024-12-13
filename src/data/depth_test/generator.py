import random

# Set parameters for the test cases
n = 10**6  # Number of nodes
m = 2 * 10**6  # Total number of edges
depths = [10**i for i in range(0, 7) if 10**i <= n]  # l = 1, 10, 100, ..., n

def generate_test_case(n, m, l, filename):
    # Initialize node indices
    indices = list(range(n))
    random.shuffle(indices)

    # Randomly select one node for each batch
    batch_indices = indices[:l]
    remaining_indices = indices[l:]

    # Create l batches and assign one node to each
    batches = [[] for _ in range(l)]
    for i in range(l):
        batches[i].append(batch_indices[i])

    # Randomly assign remaining nodes to batches
    for idx in remaining_indices:
        batch_num = random.randint(0, l - 1)
        batches[batch_num].append(idx)

    # Output file.std
    with open(f"{filename}.std", 'w') as f_std:
        f_std.write(f"{l}\n")
        for batch in batches:
            batch = sorted(batch)
            f_std.write(f"{len(batch)} {' '.join(map(str, batch))}\n")

    # Map node index to batch index
    node_to_batch = {}
    for batch_idx, batch in enumerate(batches):
        for node_idx in batch:
            node_to_batch[node_idx] = batch_idx

    # Generate dependencies for each node, ensuring each node has at least one dependency
    dependencies = [[] for _ in range(n)]
    edge_count = 0

    for i in range(n):
        bi = node_to_batch[i]
        if bi == 0:
            # Nodes in the first batch have no dependencies
            dependencies[i] = []
            continue
        
        # Ensure at least one dependency from the previous batch
        prev_batch_idx = bi - 1
        prev_batch_nodes = batches[prev_batch_idx]
        dep_from_prev_batch = random.choice(prev_batch_nodes)
        dependencies[i] = [dep_from_prev_batch]
        edge_count += 1

    # Add more random dependencies if the total edge count hasn't been reached
    if l > 1:
        while edge_count < m:
            i = random.randint(1, n - 1)
            prev_batch_idx = node_to_batch[i] - 1
            if prev_batch_idx < 0:
                continue  # Skip if no valid previous batch
            random_batch_idx = random.randint(0, prev_batch_idx)
            dep = random.choice(batches[random_batch_idx])
            if dep not in dependencies[i]:
                dependencies[i].append(dep)
                edge_count += 1

    for i in range(n):
        dependencies[i] = sorted(dependencies[i])

    # Output file.in
    with open(f"{filename}.in", 'w') as f_in:
        f_in.write(f"{n}\n")
        for deps in dependencies:
            f_in.write(f"{len(deps)}")
            if deps:
                f_in.write(' ' + ' '.join(map(str, deps)))
            f_in.write('\n')

# Generate test cases for different depths
if __name__ == "__main__":
    # Fix random seed for reproducibility
    random.seed(15618)

    for idx, l in enumerate(depths, start=1):
        print(f"Generating test case {idx} with n={n}, m={m}, depth={l}...")
        generate_test_case(n, m, l, f"{idx}")
        print(f"Test case {idx} generated successfully!")