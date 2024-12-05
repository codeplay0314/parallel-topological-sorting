---
layout: page
title:  "Milestone Report"
date:   2024-12-4
categories: /milestone/
---

[\[PDF Version\]](/parallel-topological-sorting/docs/milestone.pdf)

## Summary
Our goal for this milestone is to implement three correct topological sorting methods for Directed Acyclic Graphs (DAGs): serial, CUDA, and a Domain-Specific Language (DSL). Ensuring the correctness of these three implementations has been our primary focus up to this point. We have successfully implemented all three approaches and conducted tests to verify that they produce accurate and consistent results.


## Accomplishments

### Problem Definition
With a DAG as the input, our goal is to generate batches of nodes from the DAG, where nodes in each batch (excluding the first) strictly depend on nodes from the previous batch.

### Input File
- The first line contains an integer `n` representing the number of nodes in the DAG.
- The next `n` lines describe the nodes and their dependencies:  
  - Line `i` begins with an integer `dᵢ`, the number of dependencies of node `i`, followed by `dᵢ` integers representing the dependencies of node `i`.

It is guaranteed that the nodes and dependencies form a valid DAG.

### Output File
- The first line contains an integer `b` indicating the number of batches.
- The next `b` lines describe the batches:  
  - Line `i` begins with an integer `kᵢ`, the number of nodes in the batch, followed by `kᵢ` integers representing the nodes in that batch.


### Data Generation
Our intent is to use a number of different algorithms to generate data for this project so that we may both test different real-world scenarios and verify program correctness. So far, we have implemented three approaches:

#### Simple Data Generation
For each node, a random number of dependencies is generated within certain bounds. Similar to class labs, four data sets are created with varying difficulties: easy, medium, hard, and impossible. The count of nodes remains constant across these, but the number of dependencies doubles with each. To prevent cyclic dependencies, nodes may only depend on nodes with a lower index.

#### Exponential Probability Graph
This method generates data with the real-world property that items are more likely to depend on nearby items rather than distant ones. For example, PhD-level course requirements are often dependent on other PhD or master's coursework but less likely to depend on earlier undergraduate courses. Below is an example of the probability weights graph when `i = 1000`.
![](/parallel-topological-sorting/src/img/milestone_1.png)

#### Opposite Order Data Generation
Another way to generate data is to create the answers first and then deduce the input. We preset the number of nodes and batches, assign nodes to batches, and build the dependencies between batches. This method allows us to control the DAG structure while simultaneously generating standardized input and output for testing.


## Implementation

### Serial
The serial implementation keeps track of the incoming degree of each node and the adjacency list representing the DAG.  
The process iterates, with each iteration producing a batch. In each iteration, nodes with an incoming degree of 0 are included in a new batch, meaning they no longer have dependencies. These nodes are removed from the graph, along with their dependencies. This process continues until no nodes remain.  
Finally, the batches are written to an output file.

### CUDA
The CUDA implementation uses an adjacency matrix to represent the DAG and maintains a set of nodes that have already been batched.  
In each iteration:
- The number of dependencies is calculated by summing the values in each row of the adjacency matrix.
- Nodes whose corresponding row sums are 0 are selected to form a new batch, excluding already-batched nodes.
- These nodes are added to the set of batched nodes.
- The adjacency matrix is updated by clearing the columns corresponding to these nodes, effectively removing them from the DAG.

This process repeats until all entries in the adjacency matrix are 0.

### DSL
For this project, we used the [NetworkX library](https://networkx.org/), which simplifies working with graphs and networks. NetworkX supports directed graphs, enabling speedy development. However, since the library is written in Python, it may have performance limitations. To mitigate this, we plan to implement PyPy as well as parallel and CUDA backends. If performance is still too slow, we may pivot to alternative solutions, such as the Neo4j graph library.


## Testing
We tested the correctness of these three implementations by comparing their outputs, generated from standard inputs, against the expected standard outputs. To ensure reliability and scalability, we generated outputs of varying sizes. The data statistics are shown below:

| Scale       | Small | Medium | Large | Impossible |
|-------------|-------|--------|-------|------------|
| **# of nodes (n)**   | 100   | 1000   | 4000  | 60000      |
| **# of batches (b)** | 10    | 50     | 100   | 1000       |
| **Density (# of edges / (n * (n - 1)))** | ~0.1  | ~0.01   | ~0.01 | ~0.001     |


## Goals and Deliverables Review

### Completed
- **Implementation:**  
  - Initial programs created in all three categories: serial, CUDA, and DSL.
  - Includes:
    - A serial topological sort algorithm as a baseline
    - A CUDA-based parallel topological sort using adjacency matrix manipulation
    - A DSL-based solution using NetworkX

### Items Left Before Presentation
- **Implementation:**
  - Adjust CUDA algorithm to scale better with larger graphs
  - Experiment with DSL implementations and backends (parallel, CUDA)
  - [Optional] Explore alternative DSLs, such as Neo4j, for better performance
- **Performance Analysis:**
  - Benchmark parallel implementations against the serial baseline
  - Analyze speedup factors, scalability, resource utilization, and overheads
- **Demo for Poster Session:**
  - Performance graphs showing speedups and resource utilization
  - Code walkthrough highlighting optimization strategies
  - Interactive visualization comparing serial and parallel algorithms


## Main Concerns

### DSL Implementation
- The current DSL (NetworkX) frontend is written in Python, which may lead to poor performance.
- We are waiting to determine whether performance is too slow; if so, we may pivot to alternative solutions.
- Running the DSL’s CUDA functionality on the GHC machines requires more than 2 GB of storage (exceeding our AFS account limits). We have requested an increase and are awaiting a response.

### CUDA Implementation
- The implementation requires O(n<sup>2</sup>) space, which is problematic for large DAGs.
- Operations on the adjacency matrix introduce additional computational overhead, making it significantly slower than the serial implementation for current test cases. Further optimization is required.


## Schedule Update

### Week 1 (Nov 11 - 17)
- [x] Review literature on topological sorting
- [x] Set up development environments for C++, CUDA, and DSL tools
- [x] Implement the standard sequential topological sort
- [x] Validate correctness with sample DAGs and establish baseline performance metrics

### Week 2 (Nov 18 - 24)
- [x] Begin coding the CUDA-based topological sort
- [x] Optimize kernel functions for better memory access patterns

### Week 3 (Nov 25 - Dec 1)
- [x] Select a DSL
- [x] Implement the topological sort algorithm using the DSL

### Week 4 (Dec 2 - 8)
- [x] Test and debug issues related to correctness, concurrency, data races, and synchronization
- [ ] Collect data on execution time, speedup, scalability, and resource usage
- [ ] Analyze performance and efficiency
- [ ] Test implementations on real-world DAGs from applications like deep learning and rendering

### Week 5 (Dec 9 - 15)
- [ ] Compile findings into the final report
- [ ] Reassess goals and ensure all deliverables are met
- [ ] Rehearse the demo and prepare for the poster session
