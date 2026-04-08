#include <iostream>
#include <vector>
#include <omp.h>
#include <math.h>

int main() {
    int N = 40000; // 4万件のタスク
    std::vector<double> results(N, 0.0);
    
    double start = omp_get_wtime();
    
    // デフォルトの静的(static)割り当てで実行される
    #pragma omp parallel for schedule(dynamic)
    for (int i = 0; i < N; i++) {
        double sum = 0;
        // iが大きくなるほど、このループの回数が増えて重くなる（不均衡）
        for (int j = 0; j < i; j++) {
            sum += sin(j * 0.01);
        }
        results[i] = sum;
    }
    
    double end = omp_get_wtime();
    std::cout << "=== OpenMP (Static Scheduling) ===" << std::endl;
    std::cout << "Time: " << end - start << " sec" << std::endl;
    return 0;
}