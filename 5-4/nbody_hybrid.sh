#!/bin/bash
#SBATCH -J mpi_hybrid
#SBATCH -N 4
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-03]
#SBATCH --ntasks=112     # 全ノードの合計コア数（スロット）を最大112として確保
#SBATCH -o out/hybrid_nbody_%j.out

module load openmpi

cd "$(dirname "$0")"
mkdir -p out

echo "Nodes,MPI_Processes,OpenMP_Threads,NumParticles,Time_sec"

MPI_PROCESSES_PER_NODE_LIST=(1 2 4 7 14 28)
OMP_THREADS_LIST=(28 14 7 4 2 1)
NUM_PARTICLES=10000

for idx in "${!MPI_PROCESSES_PER_NODE_LIST[@]}"; do
	MPI_PROCESSES_PER_NODE=${MPI_PROCESSES_PER_NODE_LIST[$idx]}
	OMP_THREADS=${OMP_THREADS_LIST[$idx]}

	export OMP_NUM_THREADS=$OMP_THREADS

	srun \
		-N 4 \
		--ntasks-per-node=$MPI_PROCESSES_PER_NODE \
		--cpus-per-task=$OMP_NUM_THREADS \
		./nbody_hybrid "$NUM_PARTICLES"
done

