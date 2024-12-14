
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
# $HOME/parallel-topological-sorting/pypy3.10-linux64/bin/pypy -m venv venv_pypy
# source venv_pypy/bin/activate

# sbatch -p RM -t 00:10:00 -N 1 -n 32 ./run_psc.sh
# interact -p RM --ntasks-per-node=8
# interact -p RM -n 8

module load gcc/10.2.0

cd $HOME/parallel-topological-sorting/
source venv/bin/activate

# g++ -g serial.cpp -o serial
# ./serial data/example.in

DATA_BASEPATH="src/data"

# Arrays for each variable
APPROACHES=('node_test' 'edge_test' 'depth_test')
TEST_CASES=('1' '2' '3' '4' '5' '6' '7')

python --version

# echo ""
# echo " ----------- Staring Python3 DSL Parallel ----------- "
# echo ""

# # Loop over each combination
# for APPROACH in "${APPROACHES[@]}"; do
#     for TEST_CASE in "${TEST_CASES[@]}"; do

#         SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

#         echo "Running dsl with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#         NETWORKX_AUTOMATIC_BACKENDS=parallel python src/dsl_dag.py ${SCENARIO}

#         # python src/data/checker.py ${SCENARIO}
#     done
# done

echo ""
echo " ----------- Staring Python3 DSL GraphBLAS ----------- "
echo ""

for APPROACH in "${APPROACHES[@]}"; do
    for TEST_CASE in "${TEST_CASES[@]}"; do

        SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

        echo "Running dsl graphblas with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

        NETWORKX_AUTOMATIC_BACKENDS=graphblas python src/dsl_dag.py ${SCENARIO}

        # python src/data/checker.py ${SCENARIO}
    done
done

echo ""
echo " ----------- Staring Python3 DSL Regular ----------- "
echo ""

for APPROACH in "${APPROACHES[@]}"; do
    for TEST_CASE in "${TEST_CASES[@]}"; do

        SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

        echo "Running dsl with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

        python src/dsl_dag.py ${SCENARIO}

        # python src/data/checker.py ${SCENARIO}
    done
done

deactivate
source venv_pypy/bin/activate

python --version

# echo ""
# echo " ----------- Staring Pypy DSL Parallel ----------- "
# echo ""

# for APPROACH in "${APPROACHES[@]}"; do
#     for TEST_CASE in "${TEST_CASES[@]}"; do

#         SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

#         echo "Running dsl parallel with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#         NETWORKX_AUTOMATIC_BACKENDS=parallel python src/dsl_dag.py ${SCENARIO}

#         # python src/data/checker.py ${SCENARIO}
#     done
# done

# echo ""
# echo " ----------- Staring Pypy DSL GraphBLAS ----------- "
# echo ""

# for APPROACH in "${APPROACHES[@]}"; do
#     for TEST_CASE in "${TEST_CASES[@]}"; do

#         SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

#         echo "Running dsl graphblas with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#         NETWORKX_AUTOMATIC_BACKENDS=graphblas python src/dsl_dag.py ${SCENARIO}

#         # python src/data/checker.py ${SCENARIO}
#     done
# done

echo ""
echo " ----------- Staring Pypy DSL Regular ----------- "
echo ""

for APPROACH in "${APPROACHES[@]}"; do
    for TEST_CASE in "${TEST_CASES[@]}"; do

        SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

        echo "Running dsl with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

        python src/dsl_dag.py ${SCENARIO}

        # python src/data/checker.py ${SCENARIO}
    done
done
