#include <iostream>
#include <vector>
#include <cmath>
#include <omp.h>

#define N 100000000 // タスクA, B用の配列サイズ (1億)
#define M 1000      // タスクC用の行列サイズ (1000x1000)

// 時間計測用ヘルパー関数 (OpenMP仕様)
double get_time() {
    return omp_get_wtime();
}

// (a) 配列データの総和を求めよ (浮動小数)
// std::vectorへの「参照渡し(&)」により、無駄なメモリコピーを防ぐ
void task_a(const std::vector<double>& data) {
    double sum = 0.0;
    double start = get_time();

    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < N; i++) {
        sum += data[i];
    }

    double end = get_time();
    printf("[Task A] Sum: %f, Time: %f sec\n", sum, end - start);
}

// (b) 配列データに適当な重みの関数を作用させ総和を求める
void task_b() {
    double sum = 0.0;
    double start = get_time();

    #pragma omp parallel for reduction(+:sum)
    for (int m = 1; m <= N; m++) {
        double val = 1.0 / m;
        sum += val * std::sin(val); // C++の数学関数
    }

    double end = get_time();
    printf("[Task B] Weighted Sum: %f, Time: %f sec\n", sum, end - start);
}

// (c) 行列の積 (C = A * B)
void task_c(const std::vector<std::vector<double>>& A, const std::vector<std::vector<double>>& B, std::vector<std::vector<double>>& C) {
    double start = get_time();

    #pragma omp parallel for
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < M; j++) {
            double temp = 0.0;
            for (int k = 0; k < M; k++) {
                temp += A[i][k] * B[k][j];
            }
            C[i][j] = temp;
        }
    }

    double end = get_time();
    printf("[Task C] Matrix Multiplication (1000x1000) Time: %f sec\n", end - start);
}

int main() {
    printf("=== OpenMP Experiments (C++ Version) ===\n");
    printf("Max Threads available: %d\n\n", omp_get_max_threads());

    // --- Task A Setup ---
    // N個の要素をすべて1.0で初期化。一撃で完了。
    std::vector<double> data_a(N, 1.0); 
    task_a(data_a);

    // --- Task B Setup ---
    task_b();

    // --- Task C Setup ---
    // M x Mの2次元配列を初期値付きで一撃で作成。
    std::vector<std::vector<double>> A(M, std::vector<double>(M, 1.0));
    std::vector<std::vector<double>> B(M, std::vector<double>(M, 2.0));
    std::vector<std::vector<double>> C(M, std::vector<double>(M, 0.0));
    
    task_c(A, B, C);

    // C++のRAII（Resource Acquisition Is Initialization）という機能により、
    // 関数が終了すると自動的にすべてのメモリ（data_a, A, B, C）が解放されます。
    // free() を書く必要は一切ありません。

    return 0;
}