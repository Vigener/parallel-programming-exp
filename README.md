# 高性能並行プログラミング (主専攻実験K-9) 進捗ログ

## 5.1 OpenMPによる並列化実験

### 実行環境の比較
* **Macローカル (Dev Container)**: Apple M4チップ (10コア), ユニファイドメモリ
* **PPX (研究室クラスタ)**: x86_64 サーバー向けCPU (28コア / 1ノード)

### 実行結果とスケーリングデータ
| 環境 / スレッド数 | Task A (メモリ律速) | Task B (計算+関数) | Task C (行列計算) |
| :--- | :--- | :--- | :--- |
| Mac (C版 / 10 th) | 0.0255 sec | 0.0413 sec | 0.1453 sec |
| Mac (C++版 / 10 th)| 0.0094 sec | 0.0405 sec | 0.1421 sec |
| PPX (C++版 / 10 th)| 0.0170 sec | 0.0809 sec | 0.1423 sec |
| PPX (C++版 / 28 th)| 0.0223 sec | 0.0292 sec | 0.0599 sec |

<!-- 
```zsh
$ ./openmp_tasks
=== OpenMP Experiments (C version) ===
Max Threads available: 10

[Task A] Sum: 100000000.000000, Time: 0.025520 sec
[Task B] Weighted Sum: 1.472828, Time: 0.041322 sec
[Task C] Matrix Multiplication (1000x1000) Time: 0.145379 sec
```
```zsh
$ ./openmp_tasks
=== OpenMP Experiments (C++ Version) ===
Max Threads available: 10

[Task A] Sum: 100000000.000000, Time: 0.009439 sec
[Task B] Weighted Sum: 1.472828, Time: 0.040520 sec
[Task C] Matrix Multiplication (1000x1000) Time: 0.142101 sec
```

### PPX
```bash
$ cat out/45.out 
=== OpenMP Experiments (C++ Version) ===
Max Threads available: 10

[Task A] Sum: 100000000.000000, Time: 0.017053 sec
[Task B] Weighted Sum: 1.472828, Time: 0.080969 sec
[Task C] Matrix Multiplication (1000x1000) Time: 0.142369 sec
```
```bash
$ cat out/46.out
=== OpenMP Experiments (C++ Version) ===
Max Threads available: 28

[Task A] Sum: 100000000.000000, Time: 0.022345 sec
[Task B] Weighted Sum: 1.472828, Time: 0.029296 sec
[Task C] Matrix Multiplication (1000x1000) Time: 0.059933 sec
```
 -->

### 5.1の考察
<!-- 1. **C++ `std::vector` による最適化**: Task Aにおいて、C++のメモリ連続性とコンパイラ最適化により、C言語版と比較してMac上で約2.7倍の高速化を確認した。 -->
2. **NUMAアーキテクチャの罠とMacの驚異的なメモリ帯域**: Task A（メモリ律速）において、PPXはコア数を10から28に増やすと逆に遅延が悪化した（0.017s → 0.022s）。これはマルチソケット間でのメモリアクセス通信（NUMAの壁）がボトルネックになったためである。一方、MacのM4チップは驚異的なユニファイドメモリ帯域を持ち、同タスクを0.009秒で処理しサーバーを凌駕した。
3. **計算律速におけるエンタープライズ資産の圧倒的スケール**: Task C（行列積）のような純粋な計算リソースが求められるタスクでは、PPXの28コアが完全にスケールし（0.059秒）、スパコンの物理的な暴力が証明された。

---

## 5.2 MPIによる通信実験

### (b) ノード内（同一CPU上）プロセス間通信テスト (Macローカル先行実験)
* **目的**: 同一ノード内におけるPing-Pongテストを通じ、通信のレイテンシ $a$ とバンド幅 $b$ を測定する。
* **実行環境**: Macローカル (Dev Container), `mpirun -np 2`

**実行結果:**
| Data Size (Bytes) | Time per Half Trip (sec) |
| ---: | ---: |
| 8 | 1.88125e-07 |
| 80 | 1.55830e-07 |
| 800 | 3.01040e-07 |
| 8000 | 1.43500e-06 |
| 80000 | 5.34999e-06 |
| 800000 | 3.77301e-05 |
| 8000000 | 0.000411047 |

<!-- 
```bash
hpcuser@be68dd766e6d:/workspaces/parallel-programming-exp$ mpicxx -Wall -O3 mpi_pingpong.cpp -o mpi_pingpong
hpcuser@be68dd766e6d:/workspaces/parallel-programming-exp$ mpirun -np 2 ./mpi_pingpong
=== MPI Ping-Pong Test ===
Data_Size(Bytes)        Time_per_Half_Trip(sec)
8                       1.88125e-07
80                      1.5583e-07
800                     3.0104e-07
8000                    1.435e-06
80000                   5.34999e-06
800000                  3.77301e-05
8000000                 0.000411047
```
 -->

### 5.2 (b) の考察（ローカル環境）
* **レイテンシの特定**: 8〜80 Bytesの極小データにおいて、時間は約150〜180ナノ秒で一定となった。これが通信を準備するための固定コスト（レイテンシ $a$）である。
* **バンド幅の特定**: データサイズが80万Bytesから800万Bytesへと10倍になった際、通信時間も約10.9倍に跳ね上がった。ここから物理的な転送時間（$b$）が支配的になったことがわかる。最大サイズ時の通信速度は約 19.4 GB/s であり、Macの内部メモリの高速性が裏付けられた。

---

## 【未実施】今後のタスクリスト (To-Do)

### 5.2 (a) ノード間（別PC）の通信性能テスト
* **タスク**: PPX上でジョブスクリプト（複数ノード要求）を書き、物理的にLANケーブルを跨ぐ通信のレイテンシとバンド幅を測定。ローカル（ノード内）との速度差を比較する。

### 5.2 (d) Collective（集団）通信の性能テスト
* **タスク**: `MPI_Bcast` (1対全員) や `MPI_Allgather` (全員対全員) を実装し、Point-to-Point（手渡し）を `for` ループで回した場合との最適化の差を測定する。

### 5.2 (e) 通信の競合（ネットワーク輻輳）テスト
* **タスク**: 「2人だけの通信」と「多数のペアが同時に通信する状態」を比較し、通信経路の渋滞（ネットワーク帯域の奪い合い）が性能に与える影響を検証する。