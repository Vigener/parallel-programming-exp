#!/bin/bash
#SBATCH -J mpi_collective
#SBATCH -N 4 # 4台の計算ノード全てを要求
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-03]
#SBATCH -o out/mpi_collective_%j.out
#SBATCH --ntasks=64

module load openmpi

mkdir -p out

echo "Processes,Method,DataSize_Bytes,AvgTime_sec"

for process_count in 2 4 8 16 32 64; do
	mpirun -n "${process_count}" ./mpi_collective
done