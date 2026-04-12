#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank); // (memo) 各プロセス君に対して、自分が何番であるかを教えて、rankに保存する
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // 集団通信の違いを見るため、最低でも3プロセス以上での実行
    if (size < 2) {
        if (rank == 0) std::cerr << "Error: Requires at least 2 processes." << std::endl;
        MPI_Finalize(); return 1;
    }

    const int NUM_ITERATIONS = 100;
    const int MIN_BYTES = 8;
    const int MAX_BYTES = 16 * 1024 * 1024;

    for (int data_bytes = MIN_BYTES; data_bytes <= MAX_BYTES; data_bytes *= 2) {
        std::vector<char> send_data(data_bytes, 1);
        std::vector<char> recv_data_allgather(static_cast<size_t>(data_bytes) * static_cast<size_t>(size), 0);

        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_manual = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            if (rank == 0) {
                for (int target = 1; target < size; target++) {
                    MPI_Send(send_data.data(), data_bytes, MPI_BYTE, target, 0, MPI_COMM_WORLD);
                }
            } else {
                MPI_Recv(send_data.data(), data_bytes, MPI_BYTE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
        }
        double t_end_manual = MPI_Wtime();

        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_bcast = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            MPI_Bcast(send_data.data(), data_bytes, MPI_BYTE, 0, MPI_COMM_WORLD);
        }
        double t_end_bcast = MPI_Wtime();

        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_allgather = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            MPI_Allgather(send_data.data(), data_bytes, MPI_BYTE,
                          recv_data_allgather.data(), data_bytes, MPI_BYTE, MPI_COMM_WORLD);
        }
        double t_end_allgather = MPI_Wtime();

        double time_manual = (t_end_manual - t_start_manual) / NUM_ITERATIONS;
        double time_bcast = (t_end_bcast - t_start_bcast) / NUM_ITERATIONS;
        double time_allgather = (t_end_allgather - t_start_allgather) / NUM_ITERATION S;

        if (rank == 0) {
            printf("%d,Manual_Bcast,%d,%.9f\n", size, data_bytes, time_manual);
            printf("%d,MPI_Bcast,%d,%.9f\n", size, data_bytes, time_bcast);
            printf("%d,MPI_Allgather,%d,%.9f\n", size, data_bytes, time_allgather);
        }
    }

    MPI_Finalize();
    return 0;
}