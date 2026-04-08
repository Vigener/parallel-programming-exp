// 5.3 N 点の質点間の重力相互作用に基づき，ニュートンの運動方程式の積分を行うプログラムを作成せよ．

// OpenMP(共有メモリ)
// 全データは共有されているから、`#pragma omp parallel for`でループを並列化する
// 星iの次の位置は、他のすべての星との距離から加速度を計算して合計し、その加速度によって動く力で星iの速度,座標を更新する。

#include <iostream>
#include <vector>
#include <random> // 乱数生成用
#include <omp.h> // OpenMP用
#include <cmath> // sqrt関数用

// N点の質点を表す構造体
struct Particle {
    double mass; // 質量
    double x, y, z; // 位置
    double vx, vy, vz; // 速度
};

int main(int argc, char** argv) {
  // コマンドライン引数があればNとして読み込み、無ければデフォルト10000にする
  int N = 10000;
  if (argc > 1) {
      N = std::atoi(argv[1]);
  }
  const int STEPS = 10; // シミュレーションのステップ数(仮置き)
  const double DT = 0.01; // タイムステップ(Δt)(仮置き)
  const double G = 1.0; // 万有引力定数(仮置き)

  std::vector<Particle> particles(N); // 質点の配列

  // 質点の初期化(randomな位置と速度を設定)
  std::mt19937 gen(42); // 乱数生成（シード値は固定）
  std::uniform_real_distribution<double> position_distribution(0.0, 100.0); // 位置の範囲
  std::uniform_real_distribution<double> mass_distribution(1.0, 2.0); // 質量の範囲

  for (int i = 0; i < N; i++) {
    particles[i].x = position_distribution(gen);
    particles[i].y = position_distribution(gen);
    particles[i].z = position_distribution(gen);
    // 速度は0に初期化
    particles[i].vx = 0.0;
    particles[i].vy = 0.0;
    particles[i].vz = 0.0;
    particles[i].mass = mass_distribution(gen);
  }

  // 時間計測開始
  double start_time = omp_get_wtime();

  // シミュレーションのメインループ
  for (int step = 0; step < STEPS; step++) {
    std::vector<Particle> next_particles = particles; // 新しい位置と速度を保存するための配列

    // 力の計算と更新
    // 各星iに対して、他の全星jから受ける重力を計算する
    #pragma omp parallel for
    for (int i = 0; i < N; i++) {
      
      double acceleration_x = 0.0;
      double acceleration_y = 0.0;
      double acceleration_z = 0.0;

      // 星iに対して、他の全星jからの重力を計算
      for (int j = 0; j < N; j++) {
        if (i == j) continue; // 自分自身には力が働かない

        // 星jから星iへの距離
        double distance_x = particles[j].x - particles[i].x;
        double distance_y = particles[j].y - particles[i].y;
        double distance_z = particles[j].z - particles[i].z;

        // 距離の二乗 (r_{i,j}^2)
        double distance_squared = distance_x * distance_x + distance_y * distance_y + distance_z * distance_z;
        // バグ回避(距離が0になるのを防ぐために小さな値を加える)
        distance_squared += 1e-10;
        // 距離 (r_{i,j})
        double distance = std::sqrt(distance_squared);

        // 万有引力の計算(x,y,z方向加速度に共通するG * m_j / r_{i,j}^2の部分を計算)
        double force_magnitude = G * particles[j].mass / distance_squared;

        // 加速度の計算
        // ex) a_{x_{i,j}} = G * ( m_j / r_{i,j}^2 ) * ( x_j - x_i ) / r_{i,j} = force_magnitude * (distance_x / distance)
        acceleration_x += force_magnitude * (distance_x / distance);
        acceleration_y += force_magnitude * (distance_y / distance);
        acceleration_z += force_magnitude * (distance_z / distance);
      }

      // 速度の更新(v_{x_i}^{(\mathrm{next})}=v_{x_i}+\Delta t \sum_{j=1, j\ne i}^{N} a_{x_{i,j}})
      next_particles[i].vx = particles[i].vx + DT * acceleration_x;
      next_particles[i].vy = particles[i].vy + DT * acceleration_y;
      next_particles[i].vz = particles[i].vz + DT * acceleration_z;

      // 位置の更新(x_i^{(next)} = x_i + Δt * v_{x_i}^{(next)})
      next_particles[i].x = particles[i].x + DT * next_particles[i].vx;
      next_particles[i].y = particles[i].y + DT * next_particles[i].vy;
      next_particles[i].z = particles[i].z + DT * next_particles[i].vz;
    }

    // 更新された位置と速度を次のステップのために保存
    particles = next_particles;
  }

  // 時間計測終了
  double end_time = omp_get_wtime();

  printf("particles=%d,steps=%d,time=%.6f\n", N, STEPS, end_time - start_time);

  return 0; // main関数の終了
}