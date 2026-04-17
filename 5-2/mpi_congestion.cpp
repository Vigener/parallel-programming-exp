#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // 全プロセスを (偶数rank, 偶数rank+1) でペアにするため偶数プロセス数を要求
    if (size < 2 || size % 2 != 0) {
        if (rank == 0) std::cerr << "Error: Requires an even number of processes (>= 2)." << std::endl;
        MPI_Finalize();
        return 1;
    }

    const int NUM_ITERATIONS = 100;
    const int MIN_BYTES = 8;
    const int MAX_BYTES = 16 * 1024 * 1024;

    const int half = size / 2;
    // 自分のペア相手（rank i <-> rank i + size/2）
    const int partner = (rank < half) ? rank + half : rank - half;

    for (int data_bytes = MIN_BYTES; data_bytes <= MAX_BYTES; data_bytes *= 2) {
        std::vector<char> data(data_bytes, 1);

        // 全員同時開始で意図的に競合を発生させる
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start = MPI_Wtime();

        for (int i = 0; i < NUM_ITERATIONS; i++) {
            if (rank < half) {
                MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
                MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            } else {
                MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
            }
        }

        MPI_Barrier(MPI_COMM_WORLD);
        double t_end = MPI_Wtime();

        double elapsed_local = t_end - t_start;
        double elapsed_max = 0.0;
        MPI_Reduce(&elapsed_local, &elapsed_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

        if (rank == 0) {
            double avg_one_way_sec = elapsed_max / (2.0 * NUM_ITERATIONS);
            std::cout << size << "," << (size / 2) << "," << data_bytes << "," << avg_one_way_sec << "\n";
        }
    }

    MPI_Finalize();
    return 0;
}