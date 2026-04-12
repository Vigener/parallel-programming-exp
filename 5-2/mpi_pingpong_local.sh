#!/bin/bash
#SBATCH -J mpi_pingpong_local      # ジョブ名
#SBATCH -p ppx2
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --nodelist=ppx2-00
#SBATCH -o out/mpi_pingpong_local_%j.out        # 結果の出力

# 実行時にもMPI環境をロードする必要がある
module load openmpi

# mpirun実行 (-npを書かなくても、Slurmの -n 2 の指示を自動で読み取って2プロセス立ち上げます)
mpirun ./mpi_pingpong