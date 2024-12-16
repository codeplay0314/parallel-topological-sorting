#!/usr/bin/env bash

module load nvhpc
module load cuda

cd $HOME/parallel-topological-sorting/src

nvcc cuda.cu -o cuda_ts

DATA_BASEPATH="data"

APPROACHES=('node_test' 'edge_test' 'depth_test')
TEST_CASES=('1' '2' '3' '4' '5' '6' '7')
TEST_CASES_RW=('amazon' 'epinions' 'google' 'stanford' 'wiki')

for APPROACH in "${APPROACHES[@]}"; do
    for TEST_CASE in "${TEST_CASES[@]}"; do

        SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
        IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
        OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

        echo "Running CUDA impl with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

        ./cuda_ts ${IN} ${OUT}

        python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
    done
done

# Run RW tests
APPROACH='real_world_test'
for TEST_CASE in "${TEST_CASES_RW[@]}"; do

    SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
    IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
    OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

    echo "Running CUDA impl with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

    ./cuda_ts ${IN} ${OUT}

    python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
done

# Run with:
# sbatch -p GPU -t 00:10:00 -N 1 --gpus=v100-16:1 ./psc-run-gpu.sh
# interact -p GPU-shared -N 1 --gres=gpu:v100-32:1
# interact -p GPU-shared -N 1 --gres=gpu:v100-16:1
