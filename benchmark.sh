#!/bin/bash

# 検証する星の数(N)のリスト
N_VALUES=(1000 5000 10000 20000)
# 各Nに対する実行回数
RUNS=5

# 実行コマンドの定義 (OpenMP版のファイル名を変更)
EXEC_OMP="./nbody_omp_runtime"
EXEC_RUST="cargo run --manifest-path ./rust_experiments/Cargo.toml -q --release --bin nbody --"
EXEC_MPI="mpirun -np 4 ./nbody_mpi"

echo "=== Integrated N-Body Performance Benchmark (Local) ==="
echo "Runs per N: $RUNS"
echo "----------------------------------------------------------------------"
printf "%-10s | %-12s | %-12s | %-12s | %-12s\n" "Particles" "OMP(Static)" "OMP(Dynamic)" "Rust(Rayon)" "MPI(4-proc)"
echo "----------------------------------------------------------------------"

for N in "${N_VALUES[@]}"; do
    
    # --- 1. OpenMP 版 (Static: 0) ---
    TOTAL_OMP_STATIC=0
    for (( i=1; i<=RUNS; i++ )); do
        TIME_OUTPUT=$($EXEC_OMP $N 0 | awk -F'time=' '{print $2}')
        TOTAL_OMP_STATIC=$(awk "BEGIN {print $TOTAL_OMP_STATIC + $TIME_OUTPUT}")
    done
    AVG_OMP_STATIC=$(awk "BEGIN {printf \"%.6f\", $TOTAL_OMP_STATIC / $RUNS}")

    # --- 2. OpenMP 版 (Dynamic: 1) ---
    TOTAL_OMP_DYN=0
    for (( i=1; i<=RUNS; i++ )); do
        TIME_OUTPUT=$($EXEC_OMP $N 1 | awk -F'time=' '{print $2}')
        TOTAL_OMP_DYN=$(awk "BEGIN {print $TOTAL_OMP_DYN + $TIME_OUTPUT}")
    done
    AVG_OMP_DYN=$(awk "BEGIN {printf \"%.6f\", $TOTAL_OMP_DYN / $RUNS}")

    # --- 3. Rust 版 ---
    TOTAL_RUST=0
    for (( i=1; i<=RUNS; i++ )); do
        TIME_OUTPUT=$($EXEC_RUST $N | awk -F'time=' '{print $2}')
        TOTAL_RUST=$(awk "BEGIN {print $TOTAL_RUST + $TIME_OUTPUT}")
    done
    AVG_RUST=$(awk "BEGIN {printf \"%.6f\", $TOTAL_RUST / $RUNS}")

    # --- 4. MPI 版 ---
    TOTAL_MPI=0
    for (( i=1; i<=RUNS; i++ )); do
        TIME_OUTPUT=$($EXEC_MPI $N | awk -F'time=' '{print $2}')
        TOTAL_MPI=$(awk "BEGIN {print $TOTAL_MPI + $TIME_OUTPUT}")
    done
    AVG_MPI=$(awk "BEGIN {printf \"%.6f\", $TOTAL_MPI / $RUNS}")

    # --- 結果を出力 ---
    printf "%-10d | %-12s | %-12s | %-12s | %-12s\n" "$N" "$AVG_OMP_STATIC" "$AVG_OMP_DYN" "$AVG_RUST" "$AVG_MPI"

done
echo "----------------------------------------------------------------------"