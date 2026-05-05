#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // 1対1のペア通信のため偶数プロセス数を要求
    if (size < 2 || size % 2 != 0) {
        if (rank == 0) std::cerr << "Error: Requires an even number of processes (>= 2)." << std::endl;
        MPI_Finalize();
        return 1;
    }

    MPI_Comm node_comm;
    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, 0, MPI_INFO_NULL, &node_comm);

    int local_rank, local_size;
    MPI_Comm_rank(node_comm, &local_rank);
    MPI_Comm_size(node_comm, &local_size);

    MPI_Comm leader_comm;
    MPI_Comm_split(MPI_COMM_WORLD, (local_rank == 0) ? 0 : MPI_UNDEFINED, rank, &leader_comm);

    int node_id = -1;
    int node_count = 0;
    if (local_rank == 0) {
        MPI_Comm_rank(leader_comm, &node_id);
        MPI_Comm_size(leader_comm, &node_count);
    }
    MPI_Bcast(&node_id, 1, MPI_INT, 0, node_comm);
    MPI_Bcast(&node_count, 1, MPI_INT, 0, node_comm);

    if (node_count != 2) {
        if (rank == 0) {
            std::cerr << "Error: This benchmark requires exactly 2 nodes. Detected "
                      << node_count << " nodes." << std::endl;
        }
        if (local_rank == 0) {
            MPI_Comm_free(&leader_comm);
        }
        MPI_Comm_free(&node_comm);
        MPI_Finalize();
        return 1;
    }

    std::vector<int> node_sizes(2, 0);
    if (local_rank == 0) {
        MPI_Allgather(&local_size, 1, MPI_INT, node_sizes.data(), 1, MPI_INT, leader_comm);
    }
    MPI_Bcast(node_sizes.data(), 2, MPI_INT, 0, node_comm);

    if (node_sizes[0] != node_sizes[1]) {
        if (rank == 0) {
            std::cerr << "Error: Node0 and Node1 must have the same number of processes."
                      << " Node0=" << node_sizes[0] << ", Node1=" << node_sizes[1] << std::endl;
        }
        if (local_rank == 0) {
            MPI_Comm_free(&leader_comm);
        }
        MPI_Comm_free(&node_comm);
        MPI_Finalize();
        return 1;
    }

    std::vector<int> local_world_ranks(local_size);
    MPI_Allgather(&rank, 1, MPI_INT, local_world_ranks.data(), 1, MPI_INT, node_comm);

    std::vector<int> partner_world_ranks(local_size, -1);
    if (local_rank == 0) {
        const int peer_node_id = (node_id == 0) ? 1 : 0;
        MPI_Sendrecv(
            local_world_ranks.data(), local_size, MPI_INT, peer_node_id, 0,
            partner_world_ranks.data(), local_size, MPI_INT, peer_node_id, 0,
            leader_comm, MPI_STATUS_IGNORE
        );
    }
    MPI_Bcast(partner_world_ranks.data(), local_size, MPI_INT, 0, node_comm);

    const int partner = partner_world_ranks[local_rank];
    const bool sender_first = (node_id == 0);

    const int NUM_ITERATIONS = 10;
    const int MIN_BYTES = 8;
    const int MAX_BYTES = 16 * 1024 * 1024;

    for (int data_bytes = MIN_BYTES; data_bytes <= MAX_BYTES; data_bytes *= 2) {
        std::vector<char> data(data_bytes, 1);

        // ウォームアップ通信（1回のPing-Pong）でMPI内部の初期化ノイズを除去
        MPI_Barrier(MPI_COMM_WORLD);
        if (sender_first) {
            MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
            MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        } else {
            MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
        }

        // ダミー通信後に全員のタイミングを再同期してから本計測を開始
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start = MPI_Wtime();

        for (int i = 0; i < NUM_ITERATIONS; i++) {
            if (sender_first) {
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

    if (local_rank == 0) {
        MPI_Comm_free(&leader_comm);
    }
    MPI_Comm_free(&node_comm);

    MPI_Finalize();
    return 0;
}