// 5.3 MPI 分散メモリ版

#include <iostream>
#include <vector>
#include <cmath>
#include <mpi.h>
#include <random>
#include <cstdlib> // for std::atoi
// atoi = ASCII to Integerの略で、文字列を整数に変換する関数


struct Particle {
    double mass; // 質量
    double x, y, z; // 位置
    double vx, vy, vz; // 速度
};

int main(int argc, char** argv) {
  MPI_Init(&argc, &argv); // MPIの初期化（脳死で一番最初に書く呪文）

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank); // 自分のランク（プロセスID）を取得
  MPI_Comm_size(MPI_COMM_WORLD, &size); // 全プロセスの数を取得

  // コマンドライン引数があればNとして読み込み、無ければデフォルト10000にする
  int N = 10000;
  if (argc > 1) {
      N = std::atoi(argv[1]); // 引数は文字列なので、atoiで整数に変換する
  }

  const int STEPS = 10;
  const double DT = 0.01;
  const double G = 1.0;

  // 自分が担当する星の数を計算
  // ex) 星10000個を10プロセスで処理するとしたら、１プロセスの担当は1000個の星の計算
  // 一旦割り切れることにする。
  int local_particle_count = N / size;

  // 自分の担当を自分のrankから計算する
  // 上の例なら[rank0: 0 ~ 999], [rank1: 1000 ~ 1999], ...
  int start_index = rank * local_particle_count;
  int end_index = start_index + local_particle_count;

  // 自分の担当外も含め、全ての星の情報が計算には必要なので、
  // 全プロセスで全ての星の情報を共有するためのベクトルを用意する
  // (分散メモリなので、共有できない)
  std::vector<Particle> particles(N);

  // 星の初期化
  // （シード値はあくまで毎回の一致のため）
  // 乱数の生成はrank0だけが行い、全プロセスで共有する
  // 全体へのコピーは、MPI_Bcastを使う
  if (rank == 0) {
    std::mt19937 gen(42);
    std::uniform_real_distribution<double> position_distribution(0.0, 100.0);
    std::uniform_real_distribution<double> mass_distribution(1.0, 2.0);

    for (int i = 0; i < N; i++) {
      particles[i].x = position_distribution(gen);
      particles[i].y = position_distribution(gen);
      particles[i].z = position_distribution(gen);
      particles[i].vx = 0.0;
      particles[i].vy = 0.0;
      particles[i].vz = 0.0;
      particles[i].mass = mass_distribution(gen);
    }
  }

  // 全プロセスでparticlesの内容を共有
  // paricles構造体の全部をバイト列として送る（サイズは、N個のParticle構造体のサイズ）
  MPI_Bcast(particles.data(), N * sizeof(Particle), MPI_BYTE, 0, MPI_COMM_WORLD);

  // **待ち**
  // 全員が初期データの受け取りを終えるまで待つ
  MPI_Barrier(MPI_COMM_WORLD);

  // 時間計測開始
  double start_time = MPI_Wtime();

  // メインループ（基本の流れはOpenMP版と同じ）
  for (int step = 0; step < STEPS; step++) {
    std::vector<Particle> next_particles = particles; // 新しい位置と速度を保存するための配列

    // OpenMP版では、全ての星iに対して、全ての星jからの力を計算するのを並列化していたが、
    // MPI版では、全ての星iに対して、全ての星jからの力を計算するのは、全プロセスで分担して行う
    // つまり、自分の担当領域だけ計算をする
    for (int i = start_index; i < end_index; i++) {
      double acceleration_x = 0.0;
      double acceleration_y = 0.0;
      double acceleration_z = 0.0;

      // 引力の計算（全ての星に対して行う）
      for (int j = 0; j < N; j++) {
        if (i == j) continue; // 自分自身には力が働かない(計算しても良いが、０があるとかえってバグの元になるので、計算しない)

        double distance_x = particles[j].x - particles[i].x;
        double distance_y = particles[j].y - particles[i].y;
        double distance_z = particles[j].z - particles[i].z;

        // 距離の二乗を計算
        double distance_squared = distance_x * distance_x + distance_y * distance_y + distance_z * distance_z + 1e-10; // ゼロ割り防止のため微小値を加える
        double distance = std::sqrt(distance_squared);

        // 万有引力の計算
        double force_magnitude = G * particles[j].mass / distance_squared;

        // 加速度の計算
        acceleration_x += force_magnitude * distance_x / distance;
        acceleration_y += force_magnitude * distance_y / distance;
        acceleration_z += force_magnitude * distance_z / distance;
      }

      // 速度の更新（自分の担当する星iの速度を更新）
      next_particles[i].vx = particles[i].vx + acceleration_x * DT;
      next_particles[i].vy = particles[i].vy + acceleration_y * DT;
      next_particles[i].vz = particles[i].vz + acceleration_z * DT;       


      // 位置の更新（自分の担当する星iの位置を更新）
      next_particles[i].x = particles[i].x + next_particles[i].vx * DT;
      next_particles[i].y = particles[i].y + next_particles[i].vy * DT;
      next_particles[i].z = particles[i].z + next_particles[i].vz * DT;
    }

    // 結果の集約(Allgatherで行う)
    // MPI_Allgather(送るデータの先頭アドレス, 送るデータのサイズ, データの型, 受け取るデータの先頭アドレス, 受け取るデータのサイズ, データの型, コミュニケータ)
    MPI_Allgather(&next_particles[start_index], local_particle_count * sizeof(Particle), MPI_BYTE,
              particles.data(), local_particle_count * sizeof(Particle), MPI_BYTE, MPI_COMM_WORLD);
  }

  // 時間計測終了
  MPI_Barrier(MPI_COMM_WORLD); // 全プロセスの計算が完了したら計測終了
  double end_time = MPI_Wtime();

  if (rank == 0) {
    printf("particles=%d,steps=%d,processes=%d,time=%.6f\n", N, STEPS, size, end_time - start_time);
  }


  MPI_Finalize(); // MPIの終了（脳死で一番最後に書く呪文）
  return 0;
}