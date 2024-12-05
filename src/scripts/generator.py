import sys
import random

if len(sys.argv) != 5:
    print("Usage: python generator.py n l p filename")
    sys.exit(1)

n = int(sys.argv[1])
l = int(sys.argv[2])
p = float(sys.argv[3])
filename = sys.argv[4]

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

# Generate dependencies for each node
dependencies = [[] for _ in range(n)]
for i in range(n):
    bi = node_to_batch[i]
    deps = set()
    if bi == 0:
        # Nodes in the first batch have no dependencies
        dependencies[i] = []
        continue
    # Ensure at least one dependency from the previous batch
    prev_batch_idx = bi - 1
    prev_batch_nodes = batches[prev_batch_idx]
    dep_from_prev_batch = random.choice(prev_batch_nodes)
    deps.add(dep_from_prev_batch)
    # Consider dependencies from earlier batches
    for b_idx in range(prev_batch_idx):
        d = bi - b_idx  # Batch difference
        prob = min(p / d, 1.0)  # Cap probability at 1
        if random.random() < prob:
            possible_deps = batches[b_idx]
            dep = random.choice(possible_deps)
            deps.add(dep)
    dependencies[i] = sorted(list(deps))

# Output file.in
with open(f"{filename}.in", 'w') as f_in:
    f_in.write(f"{n}\n")
    for deps in dependencies:
        f_in.write(f"{len(deps)}")
        if deps:
            f_in.write(' ' + ' '.join(map(str, deps)))
        f_in.write('\n')
