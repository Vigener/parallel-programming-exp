#!/bin/bash
#SBATCH -J mpi_congestion
#SBATCH -N 4
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-03]
#SBATCH -o out/mpi_congestion_%j.out
#SBATCH --ntasks=64

module load openmpi

mkdir -p out

echo "Processes,Pairs,DataSize_Bytes,AvgTime_sec"

for P in 2 4 8 16 32 64; do
	mpirun -n "$P" ./mpi_congestion
done
