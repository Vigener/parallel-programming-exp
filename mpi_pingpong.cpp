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

  // テストするデータサイズの配列データサイズの配列
  std::vector<int> message_sizes = {1, 10, 100, 1000, 10000, 100000, 1000000};
  const int NUM_ITERATIONS = 100; // 各サイズでの通信を100回繰り返す

  if (rank == 0) {
    std::cout << "=== MPI Ping-Pong Test ===" << std::endl;
    std::cout << "Data_Size(Bytes)\tTime_per_Half_Trip(sec)" << std::endl;
  }

  for (int count : message_sizes) {
    // 送受信用のデータ箱を用意
    std::vector<double> data(count, 1.0);
    int data_bytes = count * sizeof(double);

    MPI_Barrier(MPI_COMM_WORLD); // 全プロセスがここまで来るのを待つ

    // 時間計測開始
    double start_time = MPI_Wtime();
    for (int i = 0; i < NUM_ITERATIONS; i++) {
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
      double time_per_half_trip = (end_time - start_time) / (2.0 * NUM_ITERATIONS);
      std::cout << data_bytes << "\t\t\t" << time_per_half_trip << std::endl;
    }

    // 最後全員で退出
    MPI_Finalize();
    return 0;
  }
}