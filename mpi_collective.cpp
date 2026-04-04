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

    std::vector<int> message_sizes = {1, 10, 100, 1000, 10000, 100000, 1000000};
    const int NUM_ITERATIONS = 100;

    if (rank == 0) {
        printf("=== MPI Collective Communication Test ===\n");
        printf("Processes: %d\n", size);
        printf("Data_Bytes\tManual_Bcast(s)\tMPI_Bcast(s)\tMPI_Allgather(s)\n");
    }

    for (int count : message_sizes) {
        int data_bytes = count * sizeof(double);
        
        // 送信用のデータ（各プロセスが持つ）
        std::vector<double> send_data(count, 1.0);
        
        // Allgatherの受信には「自分を含む全員分（count * size）」の容量が必要
        std::vector<double> recv_data_allgather(count * size, 0.0);

        // ==========================================
        // 1. 手動ブロードキャスト (forループでSend)
        // ==========================================
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_manual = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            if (rank == 0) {
                for (int target = 1; target < size; target++) {
                    MPI_Send(send_data.data(), count, MPI_DOUBLE, target, 0, MPI_COMM_WORLD);
                }
            } else {
                MPI_Recv(send_data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
        }
        double t_end_manual = MPI_Wtime();

        // ==========================================
        // 2. 最適化された MPI_Bcast
        // ==========================================
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_bcast = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            // これ1行で、Rank 0のデータが全員にツリー状で安全に配られる
            MPI_Bcast(send_data.data(), count, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        }
        double t_end_bcast = MPI_Wtime();

        // ==========================================
        // 3. MPI_Allgather (全員が全員に送る最も重い通信)
        // ==========================================
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_allgather = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            // send_data を全員が持ち寄り、recv_data_allgather に結合して保存する
            MPI_Allgather(send_data.data(), count, MPI_DOUBLE,
                          recv_data_allgather.data(), count, MPI_DOUBLE, MPI_COMM_WORLD);
        }
        double t_end_allgather = MPI_Wtime();

        double time_manual = (t_end_manual - t_start_manual) / NUM_ITERATIONS;
        double time_bcast = (t_end_bcast - t_start_bcast) / NUM_ITERATIONS;
        double time_allgather = (t_end_allgather - t_start_allgather) / NUM_ITERATIONS;

        // 結果出力
        if (rank == 0) {
            printf("%d\t\t%f\t%f\t%f\n", data_bytes, time_manual, time_bcast, time_allgather);
        }
    }

    MPI_Finalize();
    return 0;
}