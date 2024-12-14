#!

# cd $HOME
# wget https://www.python.org/ftp/python/3.10.16/Python-3.10.16.tar.xz
# tar xvf Python-3.10.16.tar.xz
# cd Python-3.10.16
# ./configure
# make
# 
# cd $HOME/parallel-topological-sorting/
# 
# $HOME/Python-3.10.16/python -m venv venv
# source venv/bin/activate
# 

# sbatch -p RM -t 00:10:00 -N 1 -n 32 ./run_psc.sh

# sbatch -p GPU -t 00:10:00 -N 1 --gpus=v100-16:1 ./psc-run-gpu.sh
# interact -p GPU-shared -N 1 --gres=gpu:v100-32:1
# interact -p GPU-shared -N 1 --gres=gpu:v100-16:1

# nvcc -o topological_sort cuda.cu

# module load gcc/10.2.0

module load nvhpc
module load cuda

cd $HOME/parallel-topological-sorting/src
# source venv/bin/activate

nvcc -o topological_sort cuda.cu

DATA_BASEPATH="src/data"

APPROACHES=('node_test' 'edge_test' 'depth_test')
TEST_CASES=('1' '2' '3' '4' '5' '6' '7')

# python --version

# # Loop over each combination
# for APPROACH in "${APPROACHES[@]}"; do
#     for TEST_CASE in "${TEST_CASES[@]}"; do

#         SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

#         echo "Running cugraph with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#         NETWORKX_AUTOMATIC_BACKENDS=cugraph python src/dsl_dag.py ${SCENARIO}

#         # python src/data/checker.py ${SCENARIO}
#     done
# done

# deactivate
# source venv_pypy/bin/activate

# python --version

# for APPROACH in "${APPROACHES[@]}"; do
#     for TEST_CASE in "${TEST_CASES[@]}"; do

#         SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

#         echo "Running cugraph pypy with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#         NETWORKX_AUTOMATIC_BACKENDS=cugraph python src/dsl_dag.py ${SCENARIO}

#         # python src/data/checker.py ${SCENARIO}
#     done
# done

for APPROACH in "${APPROACHES[@]}"; do
    for TEST_CASE in "${TEST_CASES[@]}"; do

        SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

        echo "Running cugraph pypy with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

        nvcc -o topological_sort cuda.cu

        # python src/data/checker.py ${SCENARIO}
    done
done
