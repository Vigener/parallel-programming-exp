#!/bin/bash
#SBATCH -J nbody_hybrid
#SBATCH -N 4
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-03]
#SBATCH --ntasks=112     # 全ノードの合計コア数（スロット）を最大112として確保
#SBATCH -o out/nbody_hybrid_%j.out

module load openmpi

cd "$(dirname "$0")"
mkdir -p out

# 実行用のヘルパー関数を定義（引数: ノード数, MPIプロセス数, OMPスレッド数）
run_exp() {
    local nodes=$1
    local mpi_procs=$2
    local omp_threads=$3
    local particles=10000  # 固定の粒子数

    export OMP_NUM_THREADS=${omp_threads}
    # -N はノード数、-n は全体のMPIプロセス数、--map-by ppr:X:node は1ノードあたりのプロセス数
    local procs_per_node=$(( mpi_procs / nodes ))

    mpirun -N ${nodes} -n ${mpi_procs} --map-by ppr:${procs_per_node}:node ./nbody_hybrid ${particles}
}

# １ノード
run_exp 1 28 1
run_exp 1 2 14
run_exp 1 4 7
run_exp 1 1 28

# ２ノード
run_exp 2 56 1
run_exp 2 4 14
run_exp 2 8 7
run_exp 2 2 28

# ４ノード
run_exp 4 112 1
run_exp 4 8 14
run_exp 4 16 7
run_exp 4 4 28

# 28コア全開 vs 27コア (OS Jitter回避)
run_exp 1 1 27
run_exp 2 2 27
run_exp 4 4 27



# # パターン1: Flat MPI (スレッドなし、プロセスのみで28コア埋める)
# run_exp 1 28 1
# run_exp 2 56 1
# run_exp 4 112 1

# # パターン2: 理想的なハイブリッド (1ノードあたり 4プロセス × 7スレッド = 28)
# run_exp 1 4 7
# run_exp 2 8 7
# run_exp 4 16 7

# # パターン3: 究極のハイブリッド (1ノードあたり 1プロセス × 28スレッド)
# run_exp 1 1 28
# run_exp 2 2 28
# run_exp 4 4 28

# # Sランク検証: 28コア全開 vs 27コア (OS Jitter回避)
# run_exp 1 1 27