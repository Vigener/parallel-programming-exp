#include <mpi.h>
#include <omp.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <random>
#include <vector>

struct Particle {
	double mass;
	double x, y, z;
	double vx, vy, vz;
};

int main(int argc, char** argv) {
	MPI_Init(&argc, &argv);

	int rank = 0;
	int size = 1;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	int N = 10000;
	if (argc > 1) {
		N = std::atoi(argv[1]);
	}

	int use_dynamic = 0;
	if (argc > 2) {
		use_dynamic = std::atoi(argv[2]);
	}

	const int STEPS = 10;
	const double DT = 0.01;
	const double G = 1.0;

	if (use_dynamic) {
		omp_set_schedule(omp_sched_dynamic, 1);
	} else {
		omp_set_schedule(omp_sched_static, 0);
	}

	const int omp_threads = omp_get_max_threads();

	std::vector<int> counts(size, 0);
	std::vector<int> displs(size, 0);
	const int base = N / size;
	const int rem = N % size;
	for (int r = 0; r < size; ++r) {
		counts[r] = base + (r < rem ? 1 : 0);
		if (r > 0) {
			displs[r] = displs[r - 1] + counts[r - 1];
		}
	}

	const int local_count = counts[rank];
	const int start_index = displs[rank];
	const int end_index = start_index + local_count;

	std::vector<int> counts_bytes(size, 0);
	std::vector<int> displs_bytes(size, 0);
	for (int r = 0; r < size; ++r) {
		counts_bytes[r] = counts[r] * static_cast<int>(sizeof(Particle));
		displs_bytes[r] = displs[r] * static_cast<int>(sizeof(Particle));
	}

	std::vector<Particle> particles(N);

	if (rank == 0) {
		std::mt19937 gen(42);
		std::uniform_real_distribution<double> position_dist(0.0, 100.0);
		std::uniform_real_distribution<double> mass_dist(1.0, 2.0);

		for (int i = 0; i < N; ++i) {
			particles[i].x = position_dist(gen);
			particles[i].y = position_dist(gen);
			particles[i].z = position_dist(gen);
			particles[i].vx = 0.0;
			particles[i].vy = 0.0;
			particles[i].vz = 0.0;
			particles[i].mass = mass_dist(gen);
		}
	}

	MPI_Bcast(particles.data(), N * static_cast<int>(sizeof(Particle)), MPI_BYTE, 0,
						MPI_COMM_WORLD);

	MPI_Comm shared_comm;
	MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, rank, MPI_INFO_NULL,
											&shared_comm);
	int local_rank = 0;
	MPI_Comm_rank(shared_comm, &local_rank);
	int is_node_leader = (local_rank == 0) ? 1 : 0;
	int nodes = 0;
	MPI_Allreduce(&is_node_leader, &nodes, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
	MPI_Comm_free(&shared_comm);

	MPI_Barrier(MPI_COMM_WORLD);
	const double start_time = MPI_Wtime();

	for (int step = 0; step < STEPS; ++step) {
		std::vector<Particle> next_particles = particles;

		#pragma omp parallel for schedule(runtime) default(none) shared(particles, next_particles, N, start_index, end_index, DT, G)
		for (int i = start_index; i < end_index; ++i) {
			double ax = 0.0;
			double ay = 0.0;
			double az = 0.0;

			for (int j = 0; j < N; ++j) {
				if (i == j) {
					continue;
				}

				const double dx = particles[j].x - particles[i].x;
				const double dy = particles[j].y - particles[i].y;
				const double dz = particles[j].z - particles[i].z;
				const double dist2 = dx * dx + dy * dy + dz * dz + 1e-10;
				const double dist = std::sqrt(dist2);
				const double f = G * particles[j].mass / dist2;

				ax += f * dx / dist;
				ay += f * dy / dist;
				az += f * dz / dist;
			}

			next_particles[i].vx = particles[i].vx + DT * ax;
			next_particles[i].vy = particles[i].vy + DT * ay;
			next_particles[i].vz = particles[i].vz + DT * az;

			next_particles[i].x = particles[i].x + DT * next_particles[i].vx;
			next_particles[i].y = particles[i].y + DT * next_particles[i].vy;
			next_particles[i].z = particles[i].z + DT * next_particles[i].vz;
		}

		MPI_Allgatherv(next_particles.data() + start_index,
									 local_count * static_cast<int>(sizeof(Particle)), MPI_BYTE,
									 particles.data(), counts_bytes.data(), displs_bytes.data(),
									 MPI_BYTE, MPI_COMM_WORLD);
	}

	MPI_Barrier(MPI_COMM_WORLD);
	const double end_time = MPI_Wtime();

	if (rank == 0) {
		std::printf("%d,%d,%d,%d,%.6f\n", nodes, size, omp_threads, N,
								end_time - start_time);
	}

	MPI_Finalize();
	return 0;
}
