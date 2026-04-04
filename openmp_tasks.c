#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>
#include <sys/time.h>

#define N 100000000 // タスクA, B用の配列サイズ (1億)
#define M 1000      // タスクC用の行列サイズ (1000x1000)

// 時間計測用ヘルパー関数
// 時間計測用ヘルパー関数 (OpenMP仕様)
double get_time() {
    return omp_get_wtime();
}

// (a) 配列データの総和を求めよ (浮動小数)
void task_a(double *data) {
    double sum = 0.0;
    double start = get_time();

    // reduction(+:sum) により、各スレッドのローカルsumを最後に安全に加算する
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

    // 1/m * sin(1/m) の計算。数学関数は計算コストが高いため、並列化の恩恵が大きい
    #pragma omp parallel for reduction(+:sum)
    for (int m = 1; m <= N; m++) {
        double val = 1.0 / m;
        sum += val * sin(val);
    }

    double end = get_time();
    printf("[Task B] Weighted Sum: %f, Time: %f sec\n", sum, end - start);
}

// (c) 行列の積 (C = A * B)
void task_c(double **A, double **B, double **C) {
    double start = get_time();

    // 外側のループ(i)を並列化。
    // i, j, kはループ内で宣言(int)されているため、OpenMPの仕様により自動的にスレッドのプライベート変数となる。
    #pragma omp parallel for
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < M; j++) {
            double temp = 0.0;
            // 一時変数tempを使って計算し、最後にC[i][j]に代入することでメモリアクセスを最適化
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
    printf("=== OpenMP Experiments ===\n");
    printf("Max Threads available: %d\n\n", omp_get_max_threads());

    // --- Task A Setup ---
    double *data_a = (double *)malloc(N * sizeof(double));
    for (int i = 0; i < N; i++) data_a[i] = 1.0; // 期待される和は N
    task_a(data_a);
    free(data_a);

    // --- Task B Setup ---
    task_b();

    // --- Task C Setup ---
    double **A = (double **)malloc(M * sizeof(double *));
    double **B = (double **)malloc(M * sizeof(double *));
    double **C = (double **)malloc(M * sizeof(double *));
    for (int i = 0; i < M; i++) {
        A[i] = (double *)malloc(M * sizeof(double));
        B[i] = (double *)malloc(M * sizeof(double));
        C[i] = (double *)malloc(M * sizeof(double));
        for (int j = 0; j < M; j++) {
            A[i][j] = 1.0; 
            B[i][j] = 2.0; 
            C[i][j] = 0.0;
        }
    }
    
    task_c(A, B, C);

    // メモリ解放
    for (int i = 0; i < M; i++) {
        free(A[i]); free(B[i]); free(C[i]);
    }
    free(A); free(B); free(C);

    return 0;
}