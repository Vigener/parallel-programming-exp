#!/bin/bash
#SBATCH -J mpi_pingpong_crossnode      # ジョブ名
#SBATCH -p ppx2
#SBATCH -N 2
#SBATCH -n 2
#SBATCH --ntasks-per-node=1
#SBATCH --nodelist=ppx2-00,ppx2-01
#SBATCH -o out/mpi_pingpong_crossnode_%j.out        # 結果の出力

# 実行時にもMPI環境をロードする必要がある
module load openmpi

# mpirun実行 (-npを書かなくても、Slurmの -n 2 の指示を自動で読み取って2プロセス立ち上げます)
mpirun ./mpi_pingpong
