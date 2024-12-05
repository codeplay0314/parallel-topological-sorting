package main

import (
	"fmt"
	"math"
	"math/rand"
	"os"
)

type Nodes struct {
	Name  string
	Items []Node
}

func (n *Nodes) WriteToFile() {
	fname := fmt.Sprintf("src/data/%s.in", n.Name)
	f, err := os.Create(fname)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	_, err = fmt.Fprintf(f, "%d\n", len(n.Items))
	if err != nil {
		return
	}

	for _, item := range n.Items {
		_, err := fmt.Fprintf(f, "%s\n", item)
		if err != nil {
			return
		}
	}
}

type Node struct {
	Index          int
	DepCntAttempts int
	Dependencies   []int
	Population     []int
	Weights        []float64
}

func (n *Node) SetWeights() {
	num := float64(n.Index) / 2
	denom := float64(n.Index) / 10

	for x := 0; x < n.Index; x++ {
		y := 100 / (1 + math.Exp(-(float64(x)-num)/denom))
		n.Population[x] = x
		n.Weights[x] = y
	}
}

func (n *Node) GenerateRandomDependencies() {
	for i := 0; i < e.depCntAttempts; i++ {
		if len(e.weights) == 0 {
			continue
		}
		newDep := e.population[rand.Intn(len(e.population))]
		if !contains(e.dependencies, newDep) {
			e.dependencies = append(e.dependencies, newDep)
		}
	}
}

func main() {
	entryCount := 65536
	i := 16
	GenerateEntries("easy", entryCount, i, i*2).WriteToFile()
}
