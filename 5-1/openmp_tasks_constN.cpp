#include <iostream>
#include <vector>
#include <cmath>
#include <omp.h>

// 時間計測用ヘルパー関数 (OpenMP仕様)
double get_time() {
    return omp_get_wtime();
}

// (a) 配列データの総和を求めよ (整数)
// std::vectorへの「参照渡し(&)」により、無駄なメモリコピーを防ぐ
void task_a_int(int n, const std::vector<int>& data) {
    int sum = 0;
    double start = get_time();

    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < n; i++) {
        sum += data[i];
    }

    double end = get_time();
    // printf("[Task A_Int] Sum: %d, Time: %f sec\n", sum, end - start);
    std::cout << "A_Int, " << omp_get_max_threads() << ", " << n << ", " << end - start << std::endl;
}

void task_a_float(int n, const std::vector<float>& data) {
    double sum = 0.0;
    double start = get_time();

    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < n; i++) {
        sum += data[i];
    }
    double end = get_time();
    // printf("[Task A_Float] Sum: %f, Time: %f sec\n", sum, end - start);
    std::cout << "A_Float, " << omp_get_max_threads() << ", " << n << ", " << end - start << std::endl;
}

// (b) 配列データに適当な重みの関数を作用させ総和を求める
void task_b(int n) {
    double sum = 0.0;
    double start = get_time();

    #pragma omp parallel for reduction(+:sum)
    for (int m = 1; m <= n; m++) {
        double val = 1.0 / m;
        sum += val * std::sin(val);
    }

    double end = get_time();
    // printf("[Task B] Weighted Sum: %f, Time: %f sec\n", sum, end - start);
    std::cout << "B, " << omp_get_max_threads() << ", " << n << ", " << end - start << std::endl;
}

// (c) 行列の積 (C = A * B)
// A(m x k), B(k x n), C(m x n) とする
void task_c(int m, int k, int n, const std::vector<std::vector<double>>& A, const std::vector<std::vector<double>>& B, std::vector<std::vector<double>>& C) {
    double start = get_time();

    #pragma omp parallel for
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            double temp = 0.0;
            for (int l = 0; l < k; l++) {
                temp += A[i][l] * B[l][j];
            }
            C[i][j] = temp;
        }
    }

    double end = get_time();
    // printf("[Task C] Matrix Multiplication (%dx%d) Time: %f sec\n", m, n, end - start);
    std::cout << "C, " << omp_get_max_threads() << ", " << m << "x" << n << ", " << end - start << std::endl;
}
int main() {
    // --- 検証するデータサイズのリスト ---
    // Task A, B用 (10 ~ 10^6)
    // std::vector<int> sizes_AB = {10, 100, 1000, 10000, 100000, 1000000};
    // std::vector<int> sizes_A_Int_and_B = {10, 1000, 1000000, 10000000, 100000000};
    std::vector<int> sizes_A_Int_and_B = {1000000};

    // std::vector<int> sizes_A_float = {10, 1000, 1000000, 10000000, 100000000};
    std::vector<int> sizes_A_float = {1000000};
    
    // Task C用 (10 ~ 1000)
    std::vector<int> sizes_C = {10, 100, 500, 1000};


    // printf("\n--- Task A_Int: Vector Sum ---\n");
    // printf("Task,Threads,N,Time(sec)\n");
    for (int n : sizes_A_Int_and_B) {
        std::vector<int> data_a(n, 1); // データ確保
        task_a_int(n, data_a);
    }

    // printf("\n--- Task A_Float: Vector Sum ---\n");
    // printf("Task,Threads,N,Time(sec)\n");
    for (int n : sizes_A_float) {
        std::vector<float> data_a(n, 1.0f); // データ確保
        task_a_float(n, data_a);
    }

    // printf("\n--- Task B: Math Function ---\n");
    // printf("Task,Threads,N,Time(sec)\n");
    for (int n : sizes_A_Int_and_B) {
        task_b(n);
    }

    // printf("\n--- Task C: Matrix Multiplication (Cache/Complexity Test) ---\n");
    // printf("Task,Threads,N,Time(sec)\n");
    for (int size : sizes_C) {
        int m = size, k = size, n = size;
        std::vector<std::vector<double>> A(m, std::vector<double>(k, 1.0)); // Aを1で初期化
        std::vector<std::vector<double>> B(k, std::vector<double>(n, 1.0)); // Bを1で初期化
        std::vector<std::vector<double>> C(m, std::vector<double>(n, 0.0)); // Cを0で初期化
        task_c(m, k, n, A, B, C);
    }

    // printf("\n===========================================\n");
    return 0;
}