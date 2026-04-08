#!/bin/bash
#SBATCH -J nbody_bench
#SBATCH -N 2                 # 物理ノードを2台確保（壊れたノードを回避＆MPIの真価を発揮）
#SBATCH -n 4                 # MPIプロセスは4つ
#SBATCH -o out/nbody_%j.out

# 余計な小細工はせず、シンプルにモジュールをロード
module load openmpi

# 検証する星の数(N)のリスト
N_VALUES=(1000 5000 10000 20000)
RUNS=5

EXEC_OMP="./nbody_omp_runtime"
EXEC_MPI="mpirun -np 4 ./nbody_mpi"

echo "=== PPX N-Body Performance Benchmark ==="
echo "Allocated Nodes: $(scontrol show hostname $SLURM_JOB_NODELIST)"
echo "Runs per N: $RUNS"
echo "--------------------------------------------------------"
printf "%-10s | %-12s | %-12s | %-12s\n" "Particles" "OMP(Static)" "OMP(Dynamic)" "MPI(4-proc)"
echo "--------------------------------------------------------"

for N in "${N_VALUES[@]}"; do
    
    # --- 1. OpenMP 版 (Static: 0) ---
    TOTAL_OMP_STATIC=0
    for (( i=1; i<=RUNS; i++ )); do
        TIME_OUTPUT=$($EXEC_OMP $N 0 | awk -F'time=' '{print $2}')
        TIME_OUTPUT=${TIME_OUTPUT:-0}
        TOTAL_OMP_STATIC=$(awk "BEGIN {print $TOTAL_OMP_STATIC + $TIME_OUTPUT}")
    done
    AVG_OMP_STATIC=$(awk "BEGIN {printf \"%.6f\", $TOTAL_OMP_STATIC / $RUNS}")

    # --- 2. OpenMP 版 (Dynamic: 1) ---
    TOTAL_OMP_DYN=0
    for (( i=1; i<=RUNS; i++ )); do
        TIME_OUTPUT=$($EXEC_OMP $N 1 | awk -F'time=' '{print $2}')
        TIME_OUTPUT=${TIME_OUTPUT:-0}
        TOTAL_OMP_DYN=$(awk "BEGIN {print $TOTAL_OMP_DYN + $TIME_OUTPUT}")
    done
    AVG_OMP_DYN=$(awk "BEGIN {printf \"%.6f\", $TOTAL_OMP_DYN / $RUNS}")

    # --- 3. MPI 版 ---
    TOTAL_MPI=0
    for (( i=1; i<=RUNS; i++ )); do
        TIME_OUTPUT=$($EXEC_MPI $N | awk -F'time=' '{print $2}')
        TIME_OUTPUT=${TIME_OUTPUT:-0}
        TOTAL_MPI=$(awk "BEGIN {print $TOTAL_MPI + $TIME_OUTPUT}")
    done
    AVG_MPI=$(awk "BEGIN {printf \"%.6f\", $TOTAL_MPI / $RUNS}")

    # --- 結果を出力 ---
    printf "%-10d | %-12s | %-12s | %-12s\n" "$N" "$AVG_OMP_STATIC" "$AVG_OMP_DYN" "$AVG_MPI"

done
echo "--------------------------------------------------------"