#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // 競合を起こすため、プロセス数は4以上で、かつ偶数であることを要求
    if (size < 4 || size % 2 != 0) {
        if (rank == 0) std::cerr << "Error: Requires an even number of processes (>= 4)." << std::endl;
        MPI_Finalize();
        return 1;
    }

    std::vector<int> message_sizes = {1, 10, 100, 1000, 10000, 100000, 1000000};
    const int NUM_ITERATIONS = 100;

    if (rank == 0) {
        printf("=== MPI Communication Congestion Test ===\n");
        printf("Processes: %d (Pairs: %d)\n", size, size / 2);
        printf("Data_Bytes\tSingle_Pair(s)\tMultiple_Pairs(s)\n");
    }

    for (int count : message_sizes) {
        int data_bytes = count * sizeof(double);
        std::vector<double> data(count, 1.0);

        // ==========================================
        // 1. Single Pair (Rank 0 と 1 のみ通信、他は待機)
        // ==========================================
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_single = MPI_Wtime();
        
        if (rank == 0) {
            for (int i = 0; i < NUM_ITERATIONS; i++) {
                MPI_Send(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD);
                MPI_Recv(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
        } else if (rank == 1) {
            for (int i = 0; i < NUM_ITERATIONS; i++) {
                MPI_Recv(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
            }
        }
        
        // 全員が揃うまで待つ（1ペアの計測終了）
        MPI_Barrier(MPI_COMM_WORLD);
        double t_end_single = MPI_Wtime();

        // ==========================================
        // 2. Multiple Pairs (全プロセスがペアを作って一斉に通信)
        // ==========================================
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_multi = MPI_Wtime();
        
        // 自分のペア相手を決める（偶数は+1、奇数は-1）
        int partner = (rank % 2 == 0) ? rank + 1 : rank - 1;
        
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            if (rank % 2 == 0) {
                MPI_Send(data.data(), count, MPI_DOUBLE, partner, 0, MPI_COMM_WORLD);
                MPI_Recv(data.data(), count, MPI_DOUBLE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            } else {
                MPI_Recv(data.data(), count, MPI_DOUBLE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(data.data(), count, MPI_DOUBLE, partner, 0, MPI_COMM_WORLD);
            }
        }
        
        // 全員が揃うまで待つ（全員の通信終了）
        MPI_Barrier(MPI_COMM_WORLD);
        double t_end_multi = MPI_Wtime();

        if (rank == 0) {
            // 片道(Half Trip)あたりの時間を計算して出力
            printf("%d\t\t%f\t%f\n", 
                   data_bytes, 
                   (t_end_single - t_start_single) / (2.0 * NUM_ITERATIONS),
                   (t_end_multi - t_start_multi) / (2.0 * NUM_ITERATIONS));
        }
    }

    MPI_Finalize();
    return 0;
}