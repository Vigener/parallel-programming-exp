#!/bin/bash

# 検証する星の数(N)のリスト
N_VALUES=(1000 5000 10000 20000)
# 各Nに対する実行回数
RUNS=5

# 実行ファイル名
EXEC="./nbody_omp"

echo "=== N-Body Performance Benchmark ==="
echo "Execution file: $EXEC"
echo "Runs per N: $RUNS"
echo "------------------------------------"
printf "%-10s | %-15s\n" "Particles" "Average Time(s)"
echo "------------------------------------"

# Nのリストをループで回す
for N in "${N_VALUES[@]}"; do
    
    TOTAL_TIME=0

    # 指定回数だけ実行する
    for (( i=1; i<=RUNS; i++ )); do
        # 実行し、出力結果から "Time: X.XXX sec" の X.XXX の部分だけを抽出する
        # （grepでTimeの行を探し、awkで3番目の単語を取得）
        TIME_OUTPUT=$($EXEC $N | grep "Time:" | awk '{print $2}')
        
        # TOTAL_TIME に足し合わせる (bashは小数の計算が苦手なので、awkを使う)
        TOTAL_TIME=$(awk "BEGIN {print $TOTAL_TIME + $TIME_OUTPUT}")
    done

    # 平均を計算する
    AVG_TIME=$(awk "BEGIN {printf \"%.6f\", $TOTAL_TIME / $RUNS}")

    # 結果をテーブル形式で出力
    printf "%-10d | %-15s\n" "$N" "$AVG_TIME"

done
echo "------------------------------------"