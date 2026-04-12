#!/bin/bash
#SBATCH -J openmp_test       # ジョブの名前（自分でわかりやすい名前）
#SBATCH -N 1                 # 使用するノード数（OpenMPは1ノード内で完結させるので1）
#SBATCH -n 1                 # タスク数（MPIプロセスの数。今回はOpenMPだけなので1）
#SBATCH -c 28                # 1タスクあたりのコア数（スレッド数）
#SBATCH -o out/openmp_tasks_constN_%j.out        # 実行結果の保存先（%j は自動的に割り当てられるジョブIDの数字に変わる）
#SBATCH -p ppx2
#SBATCH -w ppx2-00

# Slurmが確保してくれたコア数を、OpenMPのスレッド数として環境変数にセットする
# 2の累乗で増やしつつ、物理限界（28）とその直前（24）を観測し、その後オーバーヘッド（32〜）を観測する
THREADS=(1 2 4 8 16 24 28 32 64 128)
# THREADS=(1 2)
RUNS=5

AVG_CSV="out/openmp_tasks_constN_avg.csv"

if [ "$RUNS" -lt 1 ]; then
        echo "RUNS must be >= 1"
        exit 1
fi

mkdir -p out

TMP_DATA=$(mktemp)
trap 'rm -f "$TMP_DATA"' EXIT

# 1) 各スレッド数でRUNS回ずつ実行し、一時ファイルに追記する
for t in "${THREADS[@]}"; do
        export OMP_NUM_THREADS="$t"
        for r in $(seq 1 "$RUNS"); do
                ./openmp_tasks >> "$TMP_DATA"
        done
done

# 2) 平均CSVを作る（ヘッダーは最後に付ける）
{
        echo "Task,Threads,N,AvgTime(sec),Runs"
        awk -F',' '
        {
                task = $1
                threads = $2
                n = $3
                time = $4

                gsub(/^[ \t]+|[ \t]+$/, "", task)
                gsub(/^[ \t]+|[ \t]+$/, "", threads)
                gsub(/^[ \t]+|[ \t]+$/, "", n)
                gsub(/^[ \t]+|[ \t]+$/, "", time)

                key = task "," threads "," n
                sum[key] += time + 0
                cnt[key] += 1
        }
        END {
                for (k in sum) {
                        printf "%s,%.9f,%d\n", k, sum[k] / cnt[k], cnt[k]
                }
        }
        ' "$TMP_DATA" | sort -t',' -k1,1 -k2,2n -k3,3
} > "$AVG_CSV"

# 3) 平均だけ表示
cat "$AVG_CSV"