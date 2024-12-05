package main

import (
	"fmt"
	"math"
	"math/rand"
	"os"
	"time"
)

package main

import (
"fmt"
"math"
"math/rand"
"os"
"time"
)

type Entries struct {
	name    string
	entries []*Entry
}

func NewEntries(name string, entryCount int) *Entries {
	return &Entries{name: name, entries: make([]*Entry, entryCount)}
}

func (e *Entries) WriteToFile() {
	fname := fmt.Sprintf("src/data/%s.in", e.name)
	f, err := os.Create(fname)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	fmt.Fprintf(f, "%d\n", len(e.entries))
	for _, entry := range e.entries {
		fmt.Fprintf(f, "%s\n", entry)
	}
}

func GenerateEntries(fname string, entryCount, depCntLow, depCntHigh int) *Entries {
	entries := NewEntries(fname, entryCount)
	for i := 0; i < entryCount; i++ {
		entries.entries[i] = GenerateEntry(i, depCntLow, depCntHigh)
	}
	return entries
}

type Entry struct {
	index          int
	depCntAttempts int
	dependencies   []int
	population     []int
	weights        []float64
}

func NewEntry(index, depCntAttempts int) *Entry {
	entry := &Entry{
		index:          index,
		depCntAttempts: depCntAttempts,
		dependencies:   []int{},
		population:     make([]int, index),
		weights:        make([]float64, index),
	}
	entry.SetWeights()
	return entry
}

func (e *Entry) SetWeights() {
	num := float64(e.index) / 2
	denom := float64(e.index) / 10

	for x := 0; x < e.index; x++ {
		y := 100 / (1 + math.Exp(-(float64(x)-num)/denom))
		e.population[x] = x
		e.weights[x] = y
	}
}

func (e *Entry) GenerateRandomDependencies() {
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

func (e *Entry) String() string {
	res := fmt.Sprintf("%d", len(e.dependencies))
	for _, dep := range e.dependencies {
		res += fmt.Sprintf(" %d", dep)
	}
	return res
}

func GenerateEntry(index, depCntLow, depCntHigh int) *Entry {
	depCntAttempts := rand.Intn(depCntHigh-depCntLow+1) + depCntLow
	entry := NewEntry(index, depCntAttempts)
	entry.GenerateRandomDependencies()
	return entry
}

func contains(slice []int, item int) bool {
	for _, v := range slice {
		if v == item {
			return true
		}
	}
	return false
}

func main() {
	rand.Seed(time.Now().UnixNano())
	entryCount := 65536

	i := 16
	GenerateEntries("easy", entryCount, i, i*2).WriteToFile()
	// i *= 2
	// GenerateEntries("medium", entryCount, i, i*2).WriteToFile()
	// i *= 2
	// GenerateEntries("hard", entryCount, i, i*2).WriteToFile()
	// i *= 2
	// GenerateEntries("impossible", entryCount, i, i*2).WriteToFile()
}