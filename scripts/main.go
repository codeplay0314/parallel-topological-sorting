package main

import (
	"fmt"
	"github.com/mroth/weightedrand/v2"
	"math"
	"math/rand"
	"os"
	"slices"
)

type Nodes struct {
	Name  string
	Items []Node
}

func NewNodes(name string, entryCount int) *Nodes {
	return &Nodes{
		Name:  name,
		Items: make([]Node, entryCount),
	}
}

func (n *Nodes) WriteToFile() {
	fname := fmt.Sprintf("src/data/exp/%s.in", n.Name)
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
		_, err := fmt.Fprintf(f, "%s\n", item.ToString())
		if err != nil {
			return
		}
	}

	fmt.Println(fmt.Sprintf("Finished writing to %s", fname))
}

func GenerateNodes(name string, entryCount, depCntLow, depCntHigh int) *Nodes {
	fmt.Println(fmt.Sprintf("Generating nodes for %s", name))

	nodes := NewNodes(name, entryCount)
	for i, _ := range nodes.Items {

		nodes.Items[i].SetWeights()

		depCntAttempts := rand.Intn(depCntHigh-depCntLow+1) + depCntLow

		nodes.Items[i] = *NewNode(i, depCntAttempts)
		nodes.Items[i].GenerateRandomDependencies()

		// Free memory
		nodes.Items[i].Weights = nil
		nodes.Items[i].Population = nil
		nodes.Items[i].Chooser = nil
	}
	return nodes
}

type Node struct {
	Index          int
	DepCntAttempts int
	Dependencies   []int
	Population     []int
	Weights        []float64
	Chooser        *weightedrand.Chooser[int, int]
}

func NewNode(index, depCntAttempts int) *Node {
	node := &Node{
		Index:          index,
		DepCntAttempts: depCntAttempts,
		Dependencies:   []int{},
		Population:     make([]int, index),
		Weights:        make([]float64, index),
	}

	node.SetWeights()
	return node
}

func (n *Node) SetWeights() {
	num := float64(n.Index) / 2
	denom := float64(n.Index) / 10

	choices := []weightedrand.Choice[int, int]{}

	for x := 0; x < n.Index; x++ {
		y := 100 / (1 + math.Exp(-(float64(x)-num)/denom))
		n.Population[x] = x
		n.Weights[x] = y

		choices = append(choices, weightedrand.NewChoice[int, int](x, int(y)))
	}

	if n.Index > 1 {
		var err error
		n.Chooser, err = weightedrand.NewChooser(choices...)
		if err != nil {
			panic(err)
		}
	}
}

func (n *Node) GenerateRandomDependencies() {
	for i := 0; i < n.DepCntAttempts; i++ {
		if len(n.Weights) <= 1 {
			continue
		}
		newDep := n.Population[n.Chooser.Pick()]

		if !slices.Contains(n.Dependencies, newDep) {
			n.Dependencies = append(n.Dependencies, newDep)
		}
	}
}

func (n *Node) ToString() string {

	res := fmt.Sprintf("%d", len(n.Dependencies))

	for _, v := range n.Dependencies {
		res += fmt.Sprintf(" %d", v)
	}

	return res

}

func main() {
	entryCount := 65536
	i := 16
	GenerateNodes("easy", entryCount, i, i*2).WriteToFile()
	i *= 2
	GenerateNodes("medium", entryCount, i, i*2).WriteToFile()
	i *= 2
	GenerateNodes("hard", entryCount, i, i*2).WriteToFile()
	i *= 2
	GenerateNodes("impossible", entryCount, i, i*2).WriteToFile()
}
