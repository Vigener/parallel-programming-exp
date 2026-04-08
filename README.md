# 高性能並行プログラミング (主専攻実験K-9) 進捗ログ

## 4.3 

[課題] アムダールの法則に従い，式 (4) を元に，プロセッサ数 p が無限大になった極限において，S(p)，及び E(p) がどうなるかを考察せよ．

$$
% 等式として、数式番号をつける
S(p) = \frac{T_1}{T(p)} \\
E(p) = \frac{S(p)}{p}  \\
T(p) = T_s + \frac{T_p}{p} \\
( T_1 = T_s + T_p )
$$

より、

$$
\lim_{p \to \infty} S(p) = \lim_{p \to \infty} \frac{T_s+T_p}{T_s + \frac{T_p}{p}} = \frac{T_s + T_p}{T_s} = 1 + \frac{T_p}{T_s} \\
\lim_{p \to \infty} E(p) = \lim_{p \to \infty} \frac{1}{p}\cdot\frac{T_s + T_p}{T_s + \frac{T_p}{p}} = \lim_{p \to \infty} \frac{T_s + T_p}{pT_s + T_p} = 0
$$

よって、$S(p)$は$1+\frac{T_p}{T_s}$に収束し、$E(p)$は$0$に収束する。

## 4.4

方針: 簡易的な方法として、2点を通る直線による算出を行う。
方法: [5.2]で行なった通信実験の結果をもとに、計算する。データサイズは、8 Bytes($N_1=8$)と8,000,000 Bytes($N_2=8,000,000$)の2点を用いる。
（有効数字は3桁程度で表記する）

### ノード間(5.2 a)の計算
- a（固定コスト）
データ量が極めて小さい時($N_1=8$)の時間をaの値として近似する。
$$
a \approx 9.74 \times 10^{-7} \text{ sec}
$$
- b(単位時間あたりに転送できる通信量単位)
$T_{comm} = a + \frac{N}{b}$より、$b = \frac{N}{T_{comm} - a}$で算出できるが、今回の場合、データ量0の時の固定コストではなく、$N_1=8$ Bytesの時の時間をaの値として近似しているため、実質的な２点間の傾き$\frac{\delta T}{\delta N}$の逆数をbの値として近似する。
$$
b \approx \frac{N_2 - N_1}{T_{2} - T_{1}} = \frac{8,000,000\ Bytes - 8\ Bytes}{0.000698334\ sec - 9.74 \times 10^{-7}\ sec} \\
b \approx 1.147 \times 10^9 \text{ Bytes/sec} \approx 11.4\ GB/s
$$

### ノード内(5.2 b)の計算
- a（固定コスト）
$$
a \approx 3.58 \times 10^{-7} \text{ sec}
$$
- b(単位時間あたりに転送できる通信量単位)
$$
b \approx \frac{8000000\ Bytes - 8\ Bytes}{0.000753341\ sec - 3.58 \times 10^{-7}\ sec} \\
b \approx 1.062 \times 10^9 \text{ Bytes/sec} \approx 10.6\ GB/s
$$

### まとめ

| 環境 | レイテンシ $a$ (sec) | バンド幅 $b$ (GB/s) |
| --- | ---: | ---: |
| ノード間 (5.2 a) | $9.74 \times 10^{-7}$ | 11.4 |
| ノード内 (5.2 b) | $3.58 \times 10^{-7}$ | 10.6 |

両端の２点を結んだ直線を描画すると、以下のようになる。
（両軸対数グラフのため、直線ではないが、傾きは同じである）
![alt text](images/mpi_performance_loglog_graph.png)


## 5.1 OpenMPによる並列化実験

### 実行環境の比較
* **Macローカル (Dev Container)**: Apple M4チップ (10コア), ユニファイドメモリ
* **PPX (研究室クラスタ)**: x86_64 サーバー向けCPU (28コア / 1ノード)

### 実行結果
| 環境 / 使用スレッド数 | Task A (メモリ律速) | Task B (計算+関数) | Task C (行列計算) |
| :--- | :--- | :--- | :--- |
| Mac (C版 / 10スレッド) | 0.0255 sec | 0.0413 sec | 0.1453 sec |
| Mac (C++版 / 10スレッド)| 0.0094 sec | 0.0405 sec | 0.1421 sec |
| PPX (C++版 / 10スレッド)| 0.0170 sec | 0.0809 sec | 0.1423 sec |
| PPX (C++版 / 28スレッド)| 0.0223 sec | 0.0292 sec | 0.0599 sec |

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

### 5.1の考察・メモ

- 途中からCではなく、C++での実装に切り替えた。
- PPX上では、基本的に使用スレッド数を増やすと高速化するが、Task Aについては逆に遅くなった。
- Task Cの行列計算のような計算リソースが求められるタスクでは、使用スレッド数を増やすと劇的に高速化した。

<!-- 1. **C++ `std::vector` による最適化**: Task Aにおいて、C++のメモリ連続性とコンパイラ最適化により、C言語版と比較してMac上で約2.7倍の高速化を確認した。
2. **NUMAアーキテクチャの罠とMacの驚異的なメモリ帯域**: Task A（メモリ律速）において、PPXは使用スレッド数を10から28に増やすと逆に遅延が悪化した（0.017s → 0.022s）。これはマルチソケット間でのメモリアクセス通信（NUMAの壁）がボトルネックになったためである。一方、MacのM4チップは驚異的なユニファイドメモリ帯域を持ち、同タスクを0.009秒で処理しサーバーを凌駕した。
3. **計算律速におけるエンタープライズ資産の圧倒的スケール**: Task C（行列積）のような純粋な計算リソースが求められるタスクでは、PPXの28コア環境が完全にスケールし（0.059秒）、スパコンの物理的な暴力が証明された。 -->

---

## 5.2 MPIによる通信実験

### 5.2 (a) ノード間（別PC）の通信性能テスト
<!-- * **目的**: 物理的に異なる2つの計算ノード間でPing-Pongテストを行い、ノード内通信（Macローカル）と比較した際のレイテンシとバンド幅の悪化を観測する。 -->
* **実行環境**: PPX (研究室クラスタ), Slurmジョブスクリプト (`-N 2 -n 2` 指定により2ノードにプロセスを分散)

**実行結果:**
| Data Size (Bytes) | Time per Half Trip (sec) |
| ---: | ---: |
| 8 | 9.74980e-07 |
| 80 | 1.51068e-06 |
| 800 | 1.56235e-05 |
| 8000 | 4.44288e-06 |
| 80000 | 1.79538e-05 |
| 800000 | 8.21658e-05 |
| 8000000 | 0.000698334 |

<!-- ### 5.2 (a) の考察（ノード間 vs ノード内）
1. **レイテンシ（固定の準備時間）の増大**: 
   データサイズが最も小さい8 Bytesの通信時間において、Macローカル（ノード内）が約188ナノ秒（1.88e-07 sec）だったのに対し、PPX（ノード間）では**約975ナノ秒（9.74e-07 sec）**となり、**約5.1倍の遅延**が発生した。これはデータがCPUやメモリのバスを飛び出し、ネットワークインターフェース（NIC）やスイッチ等の物理機器を経由するためのオーバーヘッド（$a$）が明確に表れた結果である。
2. **バンド幅（転送速度）の低下とネットワークのゆらぎ**:
   最大サイズである8,000,000 Bytes (8 MB) の通信時間は、Macの約411マイクロ秒に対し、PPXでは**約698マイクロ秒**となった。ここから計算される実効バンド幅は、Macの約19.4 GB/sから**約11.4 GB/s**へと低下している。
    * 計算式: $Bandwidth = \frac{Data\ Size}{Time} = \frac{8000000\ Bytes}{0.000698334\ sec} \approx 11.4\ GB/s$
3. **結論（HPCのアルゴリズム設計への示唆）**:
   ノードを跨ぐ通信は、計算機内部のメモリアクセスに比べてレイテンシが極めて大きい。したがって、MPIプログラムを高速化するには「小さなデータを何度も送る（レイテンシのペナルティを何度も受ける）」設計を避け、「データをまとめて一度に送る（バンド幅を活かす）」バルク転送のアルゴリズムを組むことが必須であると実証された。
   *(※注: 800 Bytes時に一時的な遅延が見られるが、これは共有クラスタ特有のネットワーク輻輳などの微小なゆらぎと推測される。)* -->



### 5.2 (b) ノード内（同一CPU上）プロセス間通信テスト
<!-- * **目的**: 同一ノード内におけるPing-Pongテストを通じ、通信のレイテンシ $a$ とバンド幅 $b$ を測定し、(a)のノード間通信と純粋な比較を行う。 -->
* **実行環境**: PPX (研究室クラスタ), Slurmジョブスクリプト (`-N 1 -n 2 -w ppx2-00` 指定により同一ノード内にプロセスを配置)

**実行結果:**
| Data Size (Bytes) | Time per Half Trip (sec) |
| ---: | ---: |
| 8 | 3.57885e-07 |
| 80 | 3.66985e-07 |
| 800 | 3.60743e-06 |
| 8000 | 9.55833e-06 |
| 80000 | 1.66147e-05 |
| 800000 | 7.94011e-05 |
| 8000000 | 0.000753341 |

### 5.2 (a)(b) の考察（ノード間 vs ノード内）
<!-- 1. **レイテンシ（固定の準備時間）の差**: 
   極小データ（8〜80 Bytes）の通信時間において、ノード間が約975ナノ秒（9.74e-07 sec）であったのに対し、ノード内では**約358ナノ秒（3.57e-07 sec）**へと大幅に短縮された。同一ノード内ではネットワークケーブルやスイッチを経由せず、共有メモリ空間を利用して通信が行われるため、通信の準備にかかるオーバーヘッド（$a$）が約2.7倍削減されたと言える。
2. **バンド幅（転送速度）の驚異的な同等性**:
   最大サイズである8,000,000 Bytes (8 MB) の通信時間は、ノード間で約698マイクロ秒（約 11.4 GB/s）、ノード内で約753マイクロ秒（約 10.6 GB/s）となり、**ノード間とノード内で大差がない（ほぼ同等）**という結果になった。これは、PPXのノード間ネットワーク（InfiniBand等のHPC専用インターコネクト）の実効バンド幅が極めて優秀であり、ノード内のメモリコピースピードに匹敵するレベルのインフラ資産であることを示唆している。
3. **結論（HPCアルゴリズム設計への示唆）**:
   PPXのような高性能クラスタにおいては、データの大容量転送（バンド幅）自体はノードを跨いでも大きなペナルティにならない。しかし、レイテンシには約2.7倍の確実な開きがある。したがって、分散並列化を行う際は**「少量のデータを高頻度で送受信する」設計がノード間通信の致命的なボトルネックになりやすい**ため、一度にまとめて送る（バルク転送）設計が極めて重要である。 -->


<!-- ### (b) ノード内（同一CPU上）プロセス間通信テスト (Macローカル先行実験)
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
| 8000000 | 0.000411047 | -->

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

<!-- ### 5.2 (b) の考察（ローカル環境）
* **レイテンシの特定**: 8〜80 Bytesの極小データにおいて、時間は約150〜180ナノ秒で一定となった。これが通信を準備するための固定コスト（レイテンシ $a$）である。
* **バンド幅の特定**: データサイズが80万Bytesから800万Bytesへと10倍になった際、通信時間も約10.9倍に跳ね上がった。ここから物理的な転送時間（$b$）が支配的になったことがわかる。最大サイズ時の通信速度は約 19.4 GB/s であり、Macの内部メモリの高速性が裏付けられた。
  * 計算式: $Bandwidth = \frac{Data\ Size}{Time} = \frac{8000000\ Bytes}{0.000411047\ sec} \approx 19.4\ GB/s$ -->

### 5.2 (d) Collective（集団）通信の性能テスト
<!-- * **目的**: 1対多の通信（Broadcast）や、多対多の通信（Allgather）において、手動でPoint-to-Point通信（`MPI_Send`/`Recv`）を繰り返した場合と、MPIのCollective関数（`MPI_Bcast`等）を用いた場合の性能を比較する。 -->
* **実行環境**: PPX (研究室クラスタ), 4プロセスで実行
  * **2ノード構成**: `-N 2 -n 4` (1ノードあたり2プロセスが同居)
  * **4ノード構成**: `-N 4 -n 4` (1ノードあたり1プロセスが専有)

**実行結果 (2ノード構成 / 1ノード2プロセス):**
| Data_Bytes |　手動ブロードキャスト(s) | MPI_Bcast(s) | MPI_Allgather(s) |
| ---: | ---: | ---: | ---: |
| 8 | 0.000001 | 0.000002 | 0.000002 |
| 80 | 0.000000 | 0.000000 | 0.000004 |
| 800 | 0.000035 | 0.000005 | 0.000034 |
| 8000 | 0.000009 | 0.000012 | 0.000017 |
| 80000 | 0.000031 | 0.000019 | 0.000067 |
| 800000 | 0.000215 | 0.000105 | 0.000381 |
| 8000000 | 0.001882 | 0.001502 | 0.005983 |

**実行結果 (4ノード構成 / 1ノード1プロセス):**
| Data_Bytes | 手動ブロードキャスト(s) | MPI_Bcast(s) | MPI_Allgather(s) |
| ---: | ---: | ---: | ---: |
| 8 | 0.000000 | 0.000000 | 0.000002 |
| 80 | 0.000000 | 0.000000 | 0.000003 |
| 800 | 0.000000 | 0.000003 | 0.000005 |
| 8000 | 0.000001 | 0.000012 | 0.000011 |
| 80000 | 0.000037 | 0.000033 | 0.000053 |
| 800000 | 0.000239 | 0.000207 | 0.000302 |
| 8000000 | 0.002078 | 0.001635 | 0.002860 |

### 5.2 (d) の考察（集団通信の最適化とネットワーク輻輳）
1. **Collective関数のアルゴリズム的優位性**: 
   データサイズが8MBの時、2ノード/4ノードのいずれの環境においても、手動のforループ送信（`Manual_Bcast`）より `MPI_Bcast` の方が高速に完了した。これは `MPI_Bcast` が内部的にツリー状通信等の最適化されたトポロジを利用し、レイテンシの累積を防いでいるためである。
2. **ノード数増加による Allgather の高速化（直感に反する事実）**:
   最も通信負荷の高い `MPI_Allgather` において、2ノード構成（約0.0059秒）よりも、物理的な通信距離が遠くなるはずの4ノード構成（約0.0028秒）の方が半分以下の時間で処理を完了した。
3. **結論（ネットワーク帯域の専有）**:
   2ノード構成では1台のノード上で2つのプロセスが同時に外部へ巨大なデータを送ろうとするため、ネットワークインターフェース（NIC）の帯域の奪い合い（輻輳）が発生した。一方、4ノード構成では各プロセスがノードのNIC帯域を100%独占できたため、渋滞が解消され劇的な高速化に繋がった。HPCにおいては、単にプロセスを増やすだけでなく「NICの帯域をいかに詰まらせないか」という物理層の設計が性能を左右する。

<!-- 
- 50.out -> 2ノード構成 (1ノード2プロセス)
- 51.out -> 4ノード構成 (1ノード1プロセス)

```bash
igarashi@ppxgw:~/parallel-programming-exp$ cat out/50.out
=== MPI Collective Communication Test ===
Processes: 4
Data_Bytes      Manual_Bcast(s) MPI_Bcast(s)    MPI_Allgather(s)
8               0.000001        0.000002        0.000002
80              0.000000        0.000000        0.000004
800             0.000035        0.000005        0.000034
8000            0.000009        0.000012        0.000017
80000           0.000031        0.000019        0.000067
800000          0.000215        0.000105        0.000381
8000000         0.001882        0.001502        0.005983
igarashi@ppxgw:~/parallel-programming-exp$ cat out/51.out
=== MPI Collective Communication Test ===
Processes: 4
Data_Bytes      Manual_Bcast(s) MPI_Bcast(s)    MPI_Allgather(s)
8               0.000000        0.000000        0.000002
80              0.000000        0.000000        0.000003
800             0.000000        0.000003        0.000005
8000            0.000001        0.000012        0.000011
80000           0.000037        0.000033        0.000053
800000          0.000239        0.000207        0.000302
8000000         0.002078        0.001635        0.002860
igarashi@ppxgw:~/parallel-programming-exp$ 
```
 -->

### 5.2 (e) 通信の競合（ネットワーク輻輳）テスト
* **目的**: 2者間のみで通信を行う場合（Single Pair）と、多数のプロセスが同時にペアを作って一斉に通信を行う場合（Multiple Pairs）の時間を比較し、ネットワークの帯域競合（輻輳）による性能低下を検証する。
* **実行環境**: PPX (研究室クラスタ), 2ノードに8プロセスを配置 (`-N 2 -n 8`)

**実行結果:**
| Data_Bytes | Single_Pair(s) | Multiple_Pairs(s) |
| ---: | ---: | ---: |
| 8 | 0.000001 | 0.000001 |
| 80 | 0.000001 | 0.000001 |
| 800 | 0.000003 | 0.000003 |
| 8000 | 0.000007 | 0.000009 |
| 80000 | 0.000011 | 0.000017 |
| 800000 | 0.000115 | 0.000119 |
| 8000000 | 0.001110 | 0.002026 |

<!-- 
igarashi@ppxgw:~/parallel-programming-exp$ sbatch mpi_congestion_job.sh
Submitted batch job 52
igarashi@ppxgw:~/parallel-programming-exp$ cat out/52.out
=== MPI Communication Congestion Test ===
Processes: 8 (Pairs: 4)
Data_Bytes      Single_Pair(s)  Multiple_Pairs(s)
8               0.000001        0.000001
80              0.000001        0.000001
800             0.000003        0.000003
8000            0.000007        0.000009
80000           0.000011        0.000017
800000          0.000115        0.000119
8000000         0.001110        0.002026
 -->

### 5.2 (e) の考察（ネットワーク輻輳の物理的制約）
1. **レイテンシへの影響の少なさ**: 
   データサイズが小さい場合（8〜800 Bytes）、2者間通信と多数同時通信で時間に差は見られなかった。これはデータ量がネットワーク全体の帯域幅（Bandwidth）の限界に達しておらず、道が空いている状態であるため、同時に通信が発生してもパケットの衝突や順番待ちが起きなかったためである。
2. **バンド幅の飽和と渋滞（Congestion）の発生**:
   データサイズが最大（8,000,000 Bytes = 8MB）に達した際、Single Pairの約1.11ミリ秒に対し、Multiple Pairsでは約2.03ミリ秒と、**約1.8倍の深刻な遅延**が観測された。
3. **結論（HPCトポロジの重要性）**:
   今回の実行環境（2ノード・8プロセス）では、1台のノード上に4つのプロセスが同居している。Multiple Pairsでは、これら4つのプロセスが一斉に外部ノードへ大容量データを送信しようとしたため、ノードの出口であるネットワークインターフェース（NIC）の帯域幅を奪い合う「渋滞（輻輳）」が発生した。MPIを用いた大規模な並列計算では、単に通信回数を減らすだけでなく、「各ノードのNIC帯域がパンクしないよう、通信のタイミングを分散させる」あるいは「ノードあたりのプロセス数を調整する」といった物理層を意識したチューニングが極めて重要であることが実証された。

## 寄り道: Rust(Rayon)による並列化実験

### 5.1(a) Rust(Rayon)版

```rust:src/main.rs
use rayon::prelude::*;
use std::time::Instant;

fn main() {
    let n = 100_000_000;
    
    // 1.0 で埋められた1億個の要素を持つ配列（ベクタ）を作成
    // ※これは計測時間外（準備）です
    let a: Vec<f64> = vec![1.0; n];

    // 計測開始
    let start = Instant::now();

    // 並列処理による総和計算
    // 通常のイテレータ `iter()` を `par_iter()` に変えるだけ！
    let s: f64 = a.par_iter().sum();

    // 計測終了
    let duration = start.elapsed();

    // 結果出力
    println!("=== OpenMP vs Rayon (Rust) ===");
    println!("[Task A] Sum: {:.6}, Time: {:.6} sec", s, duration.as_secs_f64());
}
```

### 5.1(a) with Rust: 実行結果
<!-- 
hpcuser@d0729cdd7725:/workspaces/parallel-programming-exp/task_a_rust$ cargo run --release
    Finished `release` profile [optimized] target(s) in 0.03s
     Running `target/release/task_a_rust`
=== OpenMP vs Rayon (Rust) ===
[Task A] Sum: 100000000.000000, Time: 0.010524 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming-exp/task_a_rust$ cargo run --release
    Finished `release` profile [optimized] target(s) in 0.02s
     Running `target/release/task_a_rust`
=== OpenMP vs Rayon (Rust) ===
[Task A] Sum: 100000000.000000, Time: 0.009364 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming-exp/task_a_rust$ cargo run --release
    Finished `release` profile [optimized] target(s) in 0.02s
     Running `target/release/task_a_rust`
=== OpenMP vs Rayon (Rust) ===
[Task A] Sum: 100000000.000000, Time: 0.008200 sec
 -->

| 実行回数 | Rust(Rayon) Task A 時間 (秒) |
| ---: | ---: |
| 1 | 0.010524 |
| 2 | 0.009364 |
| 3 | 0.008200 |

<!-- 1. **Rust(Rayon)の驚異的な性能**: Rustの並列処理ライブラリであるRayonを用いてTask Aを実装したところ、MacローカルのC++版（約0.0094秒）と同等の性能（約0.0082秒）。 -->

### Work-strealingの体感用

- 三角関数ループの実装。

- C++版: `#pragma omp parallel for` を用いてループを並列化。
   - `/workspaces/parallel-programming-exp/unbalanced.cpp`
- C++(schedule(dynamic))版: `#pragma omp parallel for schedule(dynamic)` を用いてループを並列化。
   - `/workspaces/parallel-programming-exp/unbalanced.cpp` （編集済み）
- Rust(Rayon)版: `par_iter()` を用いてループを並列化。
   - `/workspaces/parallel-programming-exp/unbalanced_rust/src/main.rs`

#### 実行結果

<!-- 
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp$ g++ -W]633;Bg++ -Wall -O3 -fopenmp unbalanced.cpp -o unbalanced
./unbalanced
=== OpenMP (Static Scheduling) ===
Time: 0.785564 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp$ ^C
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp$ g++ -W]633;Bg++ -Wall -O3 -fopenmp unbalanced.cpp -o unbalanced
./unbalanced
=== OpenMP (Static Scheduling) ===
Time: 0.798154 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp$ g++ -Wall -O3 -fopenmp unbalanced.cpp -o unbalanced
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp$ ./unbalanced
=== OpenMP (Static Scheduling) ===
Time: 0.619695 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp$ ./unbalanced
=== OpenMP (Static Scheduling) ===
Time: 0.601501 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp$ ./unbalanced
=== OpenMP (Static Scheduling) ===
Time: 0.586284 sec
 -->
<!-- 
=== Rayon (Work-Stealing) ===
Time: 0.591402 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp/unbalanced_rust$ cargo run --release
    Finished `release` profile [optimized] target(s) in 0.02s
     Running `target/release/unbalanced_rust`
=== Rayon (Work-Stealing) ===
Time: 0.576145 sec
hpcuser@d0729cdd7725:/workspaces/parallel-programming
-exp/unbalanced_rust$ cargo run --release
    Finished `release` profile [optimized] target(s) in 0.04s
     Running `target/release/unbalanced_rust`
=== Rayon (Work-Stealing) ===
Time: 0.590889 sec
 -->

| 実行回数 | C++ (OpenMP) 時間 (秒) | C++ (OpenMP + schedule(dynamic)) 時間 (秒) | Rust(Rayon) 時間 (秒) |
| ---: | ---: | ---: | ---: |
| 1 | 0.785564 | 0.586284 | 0.591402 |
| 2 | 0.798154 | 0.601501 | 0.576145 |
| 3 | 0.619695 | 0.586284 | 0.590889 |

## 5.3(e)

<!-- 
# Macローカルにおける結果

## OMP (`schedule(dynamic)`でない）

```bash
$ ./benchmark_nbody_omp.sh
=== N-Body Performance Benchmark ===
Execution file: ./nbody_omp
Runs per N: 5
------------------------------------
Particles  | Average Time(s)
------------------------------------
1000       | 0.014467       
5000       | 0.085012       
10000      | 0.327810       
20000      | 1.229782       
------------------------------------
```

## OMP(`schedule(dynamic)` )

```bash
$ ./benchmark_nbody_omp.sh
=== N-Body Performance Benchmark ===
Execution file: ./nbody_omp
Runs per N: 5
------------------------------------
Particles  | Average Time(s)
------------------------------------
1000       | 0.011139       
5000       | 0.070391       
10000      | 0.283172       
20000      | 1.115162       
------------------------------------
```

## ./benchmark.sh

```bash
$ ./benchmark.sh
=== Integrated N-Body Performance Benchmark ===
Runs per N: 5
--------------------------------------------------------
Particles  | OpenMP(s)    | Rust(s)      | MPI(s)      
--------------------------------------------------------
1000       | 0.009518     | 0.007638     | N/A         
5000       | 0.071692     | 0.084904     | N/A         
10000      | 0.273438     | 0.297178     | N/A         
20000      | 1.114956     | 1.260534     | N/A         
--------------------------------------------------------
```
 -->

<!-- 
=== PPX N-Body Performance Benchmark ===
Runs per N: 3
--------------------------------------------------------
Particles  | OMP(Static)  | OMP(Dynamic) | MPI(4-proc) 
--------------------------------------------------------
1000       | 0.012989     | 0.005777     | 0.004749    
5000       | 0.084548     | 0.071633     | 0.125297    
10000      | 0.325343     | 0.284311     | 0.504013    
20000      | 1.218463     | 1.241327     | 1.990713    
--------------------------------------------------------
 -->

### 実行環境
* **プラットフォーム**: PPX (Tsukuba CCS)
* **条件**: 
  * OpenMP: Static / Dynamic スケジューリング
  * MPI: 4プロセス並列 (`-np 4`)
* **試行回数**: 各 $N$ に対して 3回実行した平均値

### 計測結果 (単位: 秒)

| Particles ($N$) | OpenMP (Static) | OpenMP (Dynamic) | MPI (4-proc) |
| --: | --: | --: | --: |
| **1000** | 0.012989 | 0.005777 | 0.004749 |
| **5000** | 0.084548 | 0.071633 | 0.125297 |
| **10000** | 0.325343 | 0.284311 | 0.504013 |
| **20000** | 1.218463 | 1.241327 | 1.990713 |

<!-- ### 考察とインサイト
1. **アルゴリズム計算量の実証**: 
   $N=10000$ から $N=20000$ にかけて、星の数が2倍になると計算時間は約3.7〜3.9倍に増加している。これはN体問題の理論的な計算量 $O(N^2)$ （データ量が2倍になれば計算量は4倍になる）に極めて忠実に従っていることを示している。
2. **共有メモリ (OpenMP) の挙動**: 
   StaticとDynamicで大きな性能差は見られない。これは、各星の重力計算にかかる負荷が均質であるため、動的なタスク割り当ての恩恵が薄いためであると推測される。
3. **通信オーバーヘッドの壁 (MPI)**: 
   今回のPPX上の計測結果では、$N \ge 5000$ において、MPI（4プロセス）がOpenMPよりも遅い結果となった。これは、ステップ毎に全プロセスの位置情報を共有するための集合通信（`MPI_Allgather`）のオーバーヘッドが、計算の並列化による恩恵を上回ってしまったためと考えられる。分散メモリ環境においては、通信と計算の粒度（Granularity）のバランス設計が極めて重要であることがデータから実証された。 -->
