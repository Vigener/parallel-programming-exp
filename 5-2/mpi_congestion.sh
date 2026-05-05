#!/bin/bash
#SBATCH -J mpi_congestion
#SBATCH -N 2
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-01]
#SBATCH -o out/mpi_congestion_%j.out
#SBATCH --ntasks=56

module load openmpi

mkdir -p out

echo "Processes,Pairs,DataSize_Bytes,AvgTime_sec"

for P in 2 4 8 16 32 56; do
	PER_NODE=$((P / 2))
	mpirun -n "$P" --map-by "ppr:${PER_NODE}:node" ./mpi_congestion
done
