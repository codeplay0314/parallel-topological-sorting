#!/usr/bin/env bash

module load gcc/10.2.0

# cd $HOME/parallel-topological-sorting
# source venv_pypy/bin/activate

cd $HOME/parallel-topological-sorting/src

g++ -g serial.cpp -o serial
g++ -fopenmp -g dsl_boost_kahn.cpp -o dsl_boost_kahn
g++ -g dsl_boost_builtin.cpp -o dsl_boost_builtin

DATA_BASEPATH="data"

# Arrays for each variable
APPROACHES=('node_test' 'edge_test' 'depth_test')
TEST_CASES=('1' '2' '3' '4' '5' '6' '7')
TEST_CASES_RW=('amazon' 'epinions' 'google' 'stanford' 'wiki')

python3 --version

# echo ""
# echo " ----------- Staring PyPy DSL Regular ----------- "
# echo ""

# for APPROACH in "${APPROACHES[@]}"; do
#     for TEST_CASE in "${TEST_CASES[@]}"; do

#         SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

#         echo "Running PyPy with APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#         python dsl_networkx_builtin.py ${SCENARIO}

#         # python ${DATA_BASEPATH}/checker.py ${SCENARIO}
#     done
# done

# # Run RW tests
# APPROACH='real_world_test'
# for TEST_CASE in "${TEST_CASES_RW[@]}"; do

#     SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"

#     echo "Running PyPy impl with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#     python dsl_networkx_builtin.py ${SCENARIO}

#     # python ${DATA_BASEPATH}/checker.py ${SCENARIO}
# done

# deactivate

# echo ""
# echo " ----------- Staring Boost Graph Kahn ----------- "
# echo ""

# for APPROACH in "${APPROACHES[@]}"; do
#     for TEST_CASE in "${TEST_CASES[@]}"; do

#         SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
#         IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
#         OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

#         echo "Running Boost Graph Kahn with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

#         ./dsl_boost_kahn ${IN} ${OUT}

#         python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
#     done
# done

# Run RW tests
APPROACH='real_world_test'
for TEST_CASE in "${TEST_CASES_RW[@]}"; do

    SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
    IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
    OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

    echo "Running Boost Graph Kahn with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

    ./dsl_boost_kahn ${IN} ${OUT}

    python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
done


echo ""
echo " ----------- Staring Boost Graph Builtin ----------- "
echo ""

for APPROACH in "${APPROACHES[@]}"; do
    for TEST_CASE in "${TEST_CASES[@]}"; do

        SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
        IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
        OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

        echo "Running Boost Graph Builtin with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

        ./dsl_boost_builtin ${IN} ${OUT}

        python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
    done
done

# Run RW tests
APPROACH='real_world_test'
for TEST_CASE in "${TEST_CASES_RW[@]}"; do

    SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
    IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
    OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

    echo "Running Boost Graph Builtin with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

    ./dsl_boost_builtin ${IN} ${OUT}

    python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
done


echo ""
echo " ----------- Staring Serial Regular ----------- "
echo ""

for APPROACH in "${APPROACHES[@]}"; do
    for TEST_CASE in "${TEST_CASES[@]}"; do

        SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
        IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
        OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

        echo "Running Serial with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

        ./serial ${IN} ${OUT}

        python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
    done
done

# Run RW tests
APPROACH='real_world_test'
for TEST_CASE in "${TEST_CASES_RW[@]}"; do

    SCENARIO="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}"
    IN="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.in"
    OUT="${DATA_BASEPATH}/${APPROACH}/${TEST_CASE}.out"

    echo "Running Serial with parameters: APPROACH=${APPROACH}, TEST_CASE=${TEST_CASE}"

    ./serial ${IN} ${OUT}

    python3 ${DATA_BASEPATH}/checker.py ${SCENARIO}
done

# Run with:
# sbatch -p RM -t 00:10:00 -N 1 -n 32 ./psc-run-cpu.sh
# interact -p RM -n 8
