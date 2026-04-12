#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
  // MPIの初期化(全員が個室に入るイメージ)
  MPI_Init(&argc, &argv);

  int rank, size;

  // 自分が何番目のプロセス（個室）かを取得
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // 全体でいくつのプロセスがあるかを取得
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  // Ping-Pongは２者間で行うので、プロセス数が2でない場合はエラー
  if (size != 2) {
    if (rank == 0) {
      std::cerr << "Error: This program requires exactly 2 processes." << std::endl;
    }
    MPI_Finalize(); // MPIの終了(全員が個室から出るイメージ)
    return 1;
  }

  const std::size_t MIN_BYTES = 8;
  const std::size_t MAX_BYTES = 16 * 1024 * 1024; // 16 MB
  const int WARMUP_ITERATIONS = 10;

  if (rank == 0) {
    std::cout << "DataSize_Bytes,Time_sec" << std::endl;
  }

  for (std::size_t data_bytes = MIN_BYTES; data_bytes <= MAX_BYTES; data_bytes <<= 1) {
    int count = static_cast<int>(data_bytes / sizeof(double));

    // 条件に合わせて、各サイズで 100〜1000 回の往復を行う
    int num_iterations = 100;
    if (data_bytes <= 64 * 1024) {
      num_iterations = 1000;
    } else if (data_bytes <= 1024 * 1024) {
      num_iterations = 500;
    }

    // 送受信用のデータ箱を用意
    std::vector<double> data(count, 1.0);

    MPI_Barrier(MPI_COMM_WORLD); // 全プロセスがここまで来るのを待つ

    // 初回の影響を減らすため軽くウォームアップ
    for (int i = 0; i < WARMUP_ITERATIONS; i++) {
      if (rank == 0) {
        MPI_Send(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD);
        MPI_Recv(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      } else if (rank == 1) {
        MPI_Recv(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Send(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
      }
    }

    MPI_Barrier(MPI_COMM_WORLD);

    // 時間計測開始
    double start_time = MPI_Wtime();
    for (int i = 0; i < num_iterations; i++) {
      if (rank == 0) {
        // プロセス0がプロセス1にデータを送る
        // MPI_Send(送るデータ, 要素数, 型, 宛先, タグ, コミュニケータ)
        MPI_Send(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD);
        // プロセス1からの返信を待つ
        // MPI_Recv(受け取る変数, 要素数, 型, 送り主, タグ, コミュニケータ, ステータス)
        MPI_Recv(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      } else if (rank == 1) {
        // プロセス1がプロセス0からデータを受け取る
        MPI_Recv(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        // プロセス0にデータを返信する
        MPI_Send(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
      }
    }
    // 時間計測終了
    double end_time = MPI_Wtime();

    if (rank == 0) {
      // 往復時間(Ping-Pong)の合計を、回数*2 で割り、片道(Tcomm)の時間を算出
      double time_per_half_trip = (end_time - start_time) / (2.0 * num_iterations);
      std::cout << data_bytes << "," << time_per_half_trip << std::endl;
    }
  }

  // 最後全員で退出
  MPI_Finalize();
  return 0;
}