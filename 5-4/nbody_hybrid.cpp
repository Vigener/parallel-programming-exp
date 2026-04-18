#include <mpi.h>
#include <omp.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#include "../file_util/read_double_file.hpp"

struct Particle {
	double mass;
	double x, y, z;
	double vx, vy, vz;
};

int main(int argc, char** argv) {
  // 初期作業
	MPI_Init(&argc, &argv);

	int rank = 0;
	int size = 1;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

  // 引数の処理
	if (argc != 8 && argc != 9) {
		if (rank == 0) {
			std::fprintf(stderr, "usage: %s m.double x.double y.double z.double vx.double vy.double vz.double [use_dynamic]\n", argv[0]);
		}
		MPI_Finalize();
		return 1;
	} 
  
  // OpenMPのスケジューリングの設定(動的か静的か)
	int use_dynamic = 0;
	if (argc == 9) {
		use_dynamic = std::atoi(argv[8]);
	}

  // 定数の定義
	const int STEPS = 10; // ステップ数
  const double DT = 1.0; // 時間ステップ
	const double G = 1.0; // 擬似万有引力定数
	const int MEASURE_RUNS = 10; // 計測を複数回行い平均を取るための定数

	if (use_dynamic) {
		omp_set_schedule(omp_sched_dynamic, 1); // 動的スケジューリング
	} else {
		omp_set_schedule(omp_sched_static, 0); // 静的スケジューリング
	}

	const int omp_threads = omp_get_max_threads(); // OpenMPのスレッド数を取得

	std::vector<double> masses;
	std::vector<double> xs;
	std::vector<double> ys;
	std::vector<double> zs;
	std::vector<double> vxs;
	std::vector<double> vys;
	std::vector<double> vzs;
	int N = 0;

  // ランク0のプロセスが入力ファイルを読み込み、全プロセスにブロードキャストする
	if (rank == 0) {
		masses = read_double_file(argv[1]);
		xs = read_double_file(argv[2]);
		ys = read_double_file(argv[3]);
		zs = read_double_file(argv[4]);
		vxs = read_double_file(argv[5]);
		vys = read_double_file(argv[6]);
		vzs = read_double_file(argv[7]);

		N = static_cast<int>(masses.size());
		if (N <= 0 || xs.size() != masses.size() || ys.size() != masses.size() ||
				zs.size() != masses.size() || vxs.size() != masses.size() ||
				vys.size() != masses.size() || vzs.size() != masses.size()) {
			std::fprintf(stderr, "input files must have the same number of elements\n");
			MPI_Abort(MPI_COMM_WORLD, 1);
		}
	}

	MPI_Bcast(&N, 1, MPI_INT, 0, MPI_COMM_WORLD);
	if (N <= 0) {
		MPI_Abort(MPI_COMM_WORLD, 1);
	}

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

	std::vector<Particle> particles(static_cast<std::size_t>(N));
	if (rank == 0) {
		for (int i = 0; i < N; ++i) {
			particles[static_cast<std::size_t>(i)].mass = masses[static_cast<std::size_t>(i)];
			particles[static_cast<std::size_t>(i)].x = xs[static_cast<std::size_t>(i)];
			particles[static_cast<std::size_t>(i)].y = ys[static_cast<std::size_t>(i)];
			particles[static_cast<std::size_t>(i)].z = zs[static_cast<std::size_t>(i)];
			particles[static_cast<std::size_t>(i)].vx = vxs[static_cast<std::size_t>(i)];
			particles[static_cast<std::size_t>(i)].vy = vys[static_cast<std::size_t>(i)];
			particles[static_cast<std::size_t>(i)].vz = vzs[static_cast<std::size_t>(i)];
		}
	}

	MPI_Bcast(particles.data(), N * static_cast<int>(sizeof(Particle)), MPI_BYTE, 0,
						MPI_COMM_WORLD);

	char processor_name[MPI_MAX_PROCESSOR_NAME];
	int processor_name_len = 0;
	MPI_Get_processor_name(processor_name, &processor_name_len);

	std::vector<char> all_processor_names(size * MPI_MAX_PROCESSOR_NAME, '\0');
	MPI_Allgather(processor_name, MPI_MAX_PROCESSOR_NAME, MPI_CHAR,
							 all_processor_names.data(), MPI_MAX_PROCESSOR_NAME, MPI_CHAR,
							 MPI_COMM_WORLD);

	int nodes = 0;
	if (rank == 0) {
		for (int i = 0; i < size; ++i) {
			const char* current = all_processor_names.data() + i * MPI_MAX_PROCESSOR_NAME;
			bool seen = false;
			for (int j = 0; j < i; ++j) {
				const char* previous = all_processor_names.data() + j * MPI_MAX_PROCESSOR_NAME;
				if (std::strcmp(current, previous) == 0) {
					seen = true;
					break;
				}
			}
			if (!seen) {
				++nodes;
			}
		}
	}

	const std::vector<Particle> initial_particles = particles;
	double total_elapsed = 0.0;

	for (int run = 0; run < MEASURE_RUNS; ++run) {
		particles = initial_particles;

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
		total_elapsed += (end_time - start_time);
	}

	if (rank == 0) {
		const double average_elapsed = total_elapsed / static_cast<double>(MEASURE_RUNS);
		std::printf("%d,%d,%d,%d,%.6f\n", nodes, size, omp_threads, N,
								average_elapsed);
	}

	MPI_Finalize();
	return 0;
}
