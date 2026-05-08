#import ".typst/template.typ": report

#import "/assets/5-2/mpi_collective_tables.typ": collective_tables

#let show_toc = true // true: 先頭に目次を表示, false: 非表示

#show: report.with(
  title: "高性能並行プログラミング (主専攻実験K-9) \n 進捗ログ",
  show-toc: show_toc,
)


// // --- Minimal Typst Configuration ---
// #set text(
//   lang: "ja",
//   font: ("New Computer Modern", "Hiragino Mincho ProN")
// )

// // ブロックのコード（ ```lang 〜 ``` ）に対する設定
// #show raw.where(block: true): it => block(
//   fill: rgb("#f8f9fa"),    // 背景色（薄いグレー）
//   width: 100%,             // 横幅をページいっぱいに広げる
//   inset: 12pt,             // 内側の余白（上下左右）
//   radius: 6pt,             // 角の丸み
//   stroke: rgb("#e9ecef"),  // 薄い枠線を設定
//   {
//     // 言語名（lang）が指定されている場合、右上に表示するー
//     if it.lang != none {
//       place(
//         top + right,
//         text(fill: rgb("#adb5bd"), size: 8pt, weight: "bold", it.lang)
//       )
//     }
//     // コード本文のフォントとサイズを指定
//     text(font: ("JetBrains Mono", "Consolas", "Courier New", "Menlo"), size: 9.5pt, it)
//   }
// )

// // 文章中に埋め込むインラインコード（ `code` ）に対する設定
// #show raw.where(block: false): it => box(
//   fill: rgb("#f8f9fa"),
//   inset: (x: 4pt, y: 0pt),
//   outset: (y: 3pt),
//   radius: 3pt,
//   text(font: ("JetBrains Mono", "Consolas", "Courier New", "Menlo"), it)
// )

// -----------------------------------

= 課題 1： 
#strong[実験テキストの 4.3 節で挙げられている課題（アムダールの法則）に回答せよ．]

```
[4.3節 課題]:
アムダールの法則に従い，式 (4) を元に，プロセッサ数 p
が無限大になった極限において，S(p)，及び E(p) がどうなるかを考察せよ．
```
#strong[\[解答\]] 

$S\(p\)= frac(T_1, T\(p\))$, $E\(p\)= frac(S\(p\), p)$,
$T\(p\)= T_s + T_p / p$, $\(T_1 = T_s + T_p\)$ より、

$ lim_(p arrow.r oo) S\(p\)= lim_(p arrow.r oo) frac(T_s + T_p, T_s + T_p / p) = frac(T_s + T_p, T_s) = 1 + T_p / T_s\
lim_(p arrow.r oo) E\(p\)= lim_(p arrow.r oo) 1 / p dot.op frac(T_s + T_p, T_s + T_p / p) = lim_(p arrow.r oo) frac(T_s + T_p, p T_s + T_p) = 0 $

よって、$S\(p\)$は$1 + T_p / T_s$に収束し、$E\(p\)$は$0$に収束する。

= 課題 2： 
#strong[実験テキスト 5.1 節の OpenMP のプログラムについて，プログラムのソースと実行結果（スレッド数が 1 の場合と複数スレッドの場合の実行時間）を示せ．さらに，結果に対する考察を示せ]

```
[5.1節 課題]:
以下の各種処理を OpenMP によって並列化し，1 つのノード上の複数のコアで性能評価せよ．ま
ず，付録 A の「OpenMP チュートリアル」にある例（hello world, laplace 等）を実験してみよ．その後で，以下の例題を自分で記述し，実行してみよ．
(a) 配列データの総和を求めよ．（整数，浮動小数）
(b) 配列データに適当な重みの関数を作用させ総和を求める．例えば，1/m sin(1/m) を多数のm (= 1, 2, . . . , N ) に対して計算し，総和を求めてみよ．
(c) m 行 k 列の行列 A と，k 行 n 列の行列 B の積を計算し，m 行 n 列の行列 C を求めよ．
```

// == 5.1 OpenMPによる並列化実験
// <openmpによる並列化実験>
// #block[
// #set enum(numbering: "(a)", start: 1)
// + 配列データの総和(整数、浮動小数点数)
// + 関数を作用させた配列の総和(ex. 1/m sin(1/m) (m=1,2,…,N)の総和)
// + m行k列の行列Aとk行n列の行列Bの積C=AB(m行n列)の計算
// ]

== コードの説明

=== 配列サイズNを変化させて、性能評価を行うコード。

- #link(<openmp_tasks.cppのコード>)[openmp_tasks.cpp]: 
  (a),(b),(c)の時間を計測するコード。スレッド数は１で固定し、配列のサイズ(N)を変化させて計測する。
  時間の計測は、`omp_get_wtime`関数を使用した。
  - \(a), (b): $N =\[10\,1000\,10^6\,10^7\,10^8\]$
  - \(c): $m = k = n =\[10\,100\,500\,1000\]$
- #link(<openmp_tasks.shのコード>)[openmp_tasks.sh]: `openmp_tasks.cpp`を実行するシェルスクリプト。
  - スレッド数は1。
  - それぞれの計測を5回ずつ実行し、平均値を取るようにした。

// === 配列サイズを固定して、スレッド数を変化させる場合の性能評価を行うコード

// #strong[ソースコードの要素抜粋（openmp_tasks.cpp）]

// ```cpp
// // 必要なライブラリを読み込む（<iostream>, <vector>, <cmath>, <omp.h>）

// double get_time() { return omp_get_wtime(); }

// // (a) 整数配列の総和（Int版）
// void task_a_int(int n, const std::vector<int>& data) {
//   int sum = 0;
//   double start = get_time();
//   #pragma omp parallel for reduction(+:sum)
//   for (int i = 0; i < n; i++) sum += data[i];
//   std::cout << "A_Int, " << omp_get_max_threads() << ", " << n << ", " << get_time() - start << std::endl;
// }
// // task_a_float(...) も実装済み：型を float/double に変えた同様の実装

// // (b) 1/m * sin(1/m) の総和
// void task_b(int n) {
//   double sum = 0.0;
//   double start = get_time();
//   #pragma omp parallel for reduction(+:sum)
//   for (int m = 1; m <= n; m++) {
//     double v = 1.0 / m;
//     sum += v * std::sin(v);
//   }
//   std::cout << "B, " << omp_get_max_threads() << ", " << n << ", " << get_time() - start << std::endl;
// }

// // (c) 行列積 C = A * B
// void task_c(int m, int k, int n, const std::vector<std::vector<double>>& A,
//             const std::vector<std::vector<double>>& B, std::vector<std::vector<double>>& C) {
//   double start = get_time();
//   #pragma omp parallel for
//   for (int i = 0; i < m; i++)
//     for (int j = 0; j < n; j++) {
//       double tmp = 0.0;
//       for (int l = 0; l < k; l++) tmp += A[i][l] * B[l][j];
//       C[i][j] = tmp;
//     }
//   std::cout << "C, " << omp_get_max_threads() << ", " << m << "x" << n << ", " << get_time() - start << std::endl;
// }

// int main() {
//   // 配列のサイズ(N) を変えながら、それぞれの task_*() を実行
//   // - A(Int), A(Float): N = {10, 1000, 1e6, 1e7, 1e8}
//   // - B:              N = {10, 1000, 1e6, 1e7, 1e8}
//   // - C:              size = {10, 100, 500, 1000}
//   // （初期化とループ本体は省略）
// }
// ```

※掲載は要点のみ。全体コードは最終版でGitHubリンク（コミットハッシュ付き）を併記予定。

- `openmp_tasks_constN.cpp`:
  `openmp_tasks.cpp`の配列サイズを固定したもの。
  - \(a): $N = 10^6$
  - \(b): $N = 10^6$
  - \(c): $m = k = n = 100$
- `openmp_tasks_constN.sh`:
  `openmp_tasks_constN.cpp`を実行するシェルスクリプト。
  - スレッド数は、\[1, 2, 4, 8, 16, 32, 64, 128, 256\]で変化させる。
  - それぞれの計測を5回ずつ実行し、平均値を取るようにした。

== 実行環境

#strong[ppx2-00]
CPUは28コア。で`#SBATCH -c 28`で28スレッド分のコアを使用。

== 実行方法

`.cpp`をコンパイル後、`.sh`を用いて実行。

\(`openmp_tasks_constN.cpp`と`openmp_tasks_constN.sh`の例)

```bash
$ g++ -fopenmp -O2 openmp_tasks_constN.cpp -o openmp_tasks_constN
$ sbatch ./openmp_tasks_constN.sh
```

== 実行結果

=== Nを変化させた例

```out
num_of_threads = 1
Task,Threads,N,Time(sec)
A_Int, 1, 10, 1.022e-05
A_Int, 1, 1000, 3.44e-06
A_Int, 1, 1000000, 0.000178158
A_Int, 1, 10000000, 0.00322836
A_Int, 1, 100000000, 0.0239458
A_Float, 1, 10, 3.25001e-06
A_Float, 1, 1000, 2.05e-06
A_Float, 1, 1000000, 0.000902961
A_Float, 1, 10000000, 0.00950642
A_Float, 1, 100000000, 0.103777
B, 1, 10, 1.999e-05
B, 1, 1000, 8.79999e-06
B, 1, 1000000, 0.00839176
B, 1, 10000000, 0.0836077
B, 1, 100000000, 0.821955
C, 1, 10x10, 1.69e-06
C, 1, 100x100, 0.000694853
C, 1, 500x500, 0.117294
C, 1, 1000x1000, 0.92576

num_of_threads = 2
...
```

=== スレッド数を変化させた例
<スレッド数を変化させた例>
\(最初のみ抜粋)

```csv
Task,Threads,N,Time(sec)
A_Int, 1, 1000000, 0.000290827
A_Float, 1, 1000000, 0.00132624
B, 1, 1000000, 0.00916219
C, 1, 100x100, 0.00119395
A_Int, 2, 1000000, 0.000411857
```

=== $N=10^6, 10^7$(Cは100x100, 1000x1000)の時のスレッド数を変化させた時のグラフと表
<n106cは100x100の時のスレッド数を変化させた時のグラフと表>
=== Task A (整数と浮動小数点数の総和)
<task-a整数と浮動小数点数の総和>
#figure(
  grid(
    columns: 2,
    gutter: 1em,
    image("assets/5-1/openmp_tasks_constN_run5_A_N-1000000.pdf"),
    image("assets/5-1/openmp_tasks_constN_run5_A_N-10000000.pdf"),
  ),
  caption: [$N = 10^6$ および $N = 10^7$ のときのスレッド数と実行時間の関係]
)

#align(center)[
  #grid(
    columns: 2,
    gutter: 1em,
    figure(
      align(center)[#table(
        columns: 3,
        align: (auto, right, right),
        table.header([スレッド数], [A(整数) [ms]], [A(浮動小数) [ms]]),
        table.hline(),
        [1], [$172.07$], [$865.45$],
        [2], [$314.15$], [$774.87$],
        [4], [$176.93$], [$473.96$],
        [8], [$160.40$], [$253.06$],
        [16], [$143.94$], [$153.77$],
        [24], [$142.88$], [$127.66$],
        [28], [$144.87$], [$111.56$],
        [32], [$200.06$], [$294.92$],
        [64], [$244.84$], [$328.56$],
        [128], [$380.79$], [$509.52$],
      )],
      caption: [Task: A(整数 / 浮動小数) (N=$10^6$)],
      kind: table
    ),
    figure(
      align(center)[#table(
        columns: 3,
        align: (auto, right, right),
        table.header([スレッド数], [A(整数) [ms]], [A(浮動小数) [ms]]),
        table.hline(),
        [1], [$3310.75$], [$9523.65$],
        [2], [$3176.80$], [$8865.87$],
        [4], [$1772.17$], [$5353.64$],
        [8], [$1256.77$], [$2902.63$],
        [16], [$1088.58$], [$1676.62$],
        [24], [$1102.05$], [$1319.51$],
        [28], [$1150.86$], [$1227.71$],
        [32], [$1140.16$], [$1811.06$],
        [64], [$1083.77$], [$1461.48$],
        [128], [$1200.68$], [$1481.71$],
      )],
      caption: [Task: A(整数 / 浮動小数) (N=$10^7$)],
      kind: table
    )
  )
]
=== Task B (関数を作用させた配列の総和)

#figure(
  grid(
    columns: 2,
    gutter: 1em,
    image("assets/5-1/openmp_tasks_constN_run5_B_N-1000000.pdf"),
    image("assets/5-1/openmp_tasks_constN_run5_B_N-10000000.pdf"),
  ),
  caption: [$N = 10^6$ および $N = 10^7$ のときのスレッド数と実行時間の関係]
)
#align(center)[
  #grid(
    columns: 2,
    gutter: 1em,
    figure(
      align(center)[#table(
        columns: 2,
        align: (auto, right),
        table.header([スレッド数], [平均時間[ms]]),
        table.hline(),
        [1], [$6.015$],
        [2], [$4.194$],
        [4], [$3.166$],
        [8], [$2.151$],
        [16], [$1.122$],
        [24], [$0.752$],
        [28], [$0.654$],
        [32], [$1.242$],
        [64], [$1.027$],
        [128], [$1.366$],
      )],
      caption: [課題5-1 B の平均時間比較 (N=$10^6$)],
      kind: table
    ),
    figure(
      align(center)[#table(
        columns: 2,
        align: (auto, right),
        table.header([スレッド数], [平均時間[ms]]),
        table.hline(),
        [1], [$60.04$],
        [2], [$40.56$],
        [4], [$30.60$],
        [8], [$21.38$],
        [16], [$11.07$],
        [24], [$7.399$],
        [28], [$6.360$],
        [32], [$9.091$],
        [64], [$7.805$],
        [128], [$7.309$],
      )],
      caption: [課題5-1 B の平均時間比較 (N=$10^7$)],
      kind: table
    )
  )
]

=== Task C (行列積)
<task-c行列積>
#figure(
  grid(
    columns: 2,
    gutter: 1em,
    image("assets/5-1/openmp_tasks_constN_run5_C_N-100x100.pdf"),
    image("assets/5-1/openmp_tasks_constN_run5_C_N-1000x1000.pdf"),
  ),
  caption: [m = k = n = 100 および m = k = n = 1000 のときのスレッド数と実行時間の関係]
)

#align(center)[
  #grid(
    columns: 2,
    gutter: 1em,
    figure(
      align(center)[#table(
        columns: 2,
        align: (auto, right),
        table.header([スレッド数], [平均時間[ms]]),
        table.hline(),
        [1], [$0.772$],
        [2], [$0.548$],
        [4], [$0.322$],
        [8], [$0.172$],
        [16], [$0.124$],
        [24], [$0.082$],
        [28], [$0.086$],
        [32], [$0.254$],
        [64], [$0.259$],
        [128], [$0.351$],
      )],
      caption: [課題5-1 C の平均時間比較 (N=100x100)],
      kind: table
    ),
    figure(
      align(center)[#table(
        columns: 2,
        align: (auto, right),
        table.header([スレッド数], [平均時間[ms]]),
        table.hline(),
        [1], [$1232.11$],
        [2], [$626.18$],
        [4], [$392.01$],
        [8], [$202.71$],
        [16], [$107.79$],
        [24], [$77.59$],
        [28], [$70.52$],
        [32], [$88.66$],
        [64], [$65.87$],
        [128], [$61.30$],
      )],
      caption: [課題5-1 C の平均時間比較 (N=1000x1000)],
      kind: table
    )
  )
]


== 5.1の考察
<の考察>
- 全体を通した物理コア数の限界
  - すべてのタスクにおいて、スレッド数28を超えたあたりで処理時間が増加する傾向が見られた。
  - 実験環境の物理コア数は28であるため、スレッド数がそれを超えると、OSによるスレッドの切り替え（コンテキストスイッチ）やリソース競合などのオーバーヘッドが計算の恩恵を上回り、処理時間が増加してしまうと考えられる。
- 並列化のオーバーヘッド (Task A)
  - $N$が小さく処理が一瞬で終わるタスクでは、スレッド数を1から2に増やした際、処理時間が半減するどころか逆に増加する現象が見られた。
  - これは、OSが複数スレッドを生成しメモリ空間を割り当てるなどの「準備コスト」が、実際の処理時間に対して相対的に大きくなってしまうためであると考える。
  - 実際、$N$が$10^7$などある程度大きくなった場合には、半減とまではいかないものの、スレッド数の増加に伴い順調に処理時間が減少する傾向が見られるようになった。
- Task Aにおける整数と浮動小数点数の比較
  - Task Aの総和計算において、整数（Int）と浮動小数点数（Float）を比較すると、整数の方が処理時間が短い傾向が見られた。
  - 足し算の計算自体の重さの差もあるかもしれないが、1要素あたりのデータサイズの違いも影響している可能性がある。整数は通常4バイトであるのに対し、浮動小数点数は通常8バイトであるため、メモリからの読み込みやキャッシュの効率などに差が出て、これが処理時間に影響した可能性もあると考える。
- タスクの計算量とスケーリング (Task B, Task C)
  - Task BやTask Cのような計算量が多いタスクでは、スレッド数増加に伴う処理時間の減少が明確に見られた。
  - 特に、Task Bは$O(N)$の計算量であるのに対し、Task Cは$O(N^3)$の計算量であるため、Task Cの方が並列化の恩恵が顕著に現れている。実際、Task C（$N=1000 times 1000$）においてスレッド数を1から2に増やした際は、1.23秒から0.63秒へと概ね理想的な半減が確認できた。
  - ただし、Task Cであっても$N=100 times 100$の時は半減が見られなかった。これもTask Aと同様に、行列積の計算量自体がまだ小さいため、並列化のオーバーヘッドが相対的に大きくなってしまったためだと考えられる。

= 課題 3： 

#strong[実験テキスト 5.2 節の MPI 通信実験について，プログラムのソースと実行結果（通信時間）を示せ．また，実験テキスト 4.4 節の課題について，この測定結果を元に答えよ．さらに，これらの結果に対する考察を示せ.]

```
[5.2節 課題]:
付録 B「MPI による並列プログラミング」に従い，以下の各通信実験を MPI によって行い，通信性能を比較せよ．
(a) ノード間の point-to-point 通信性能を各種データ量について測定せよ．
(b) ノード内の同一 CPU 上のプロセス間での point-to-point 通信性能を測定せよ．
(c) ノード内の異なる CPU 上のプロセス間での point-to-point 通信性能を測定せよ．
(d) 各種データサイズに対し，collective 通信（allgather 等）の性能を測定せよ．
(e) point-to-point 通信を 2 者間のみで行う場合と，そういったペアの通信を多数同時に行った場合について性能を比較せよ．
```

// == 5.2 MPIによる通信実験

== 5.2 (a) ノード間（別PC）, (b) ノード内（同一CPU上）プロセス間通信テスト

=== コードの説明

- #link(<mpi_pingpong.cppのコード>)[mpi_pingpong.cpp]: MPIを用いて、プロセス間でPing-Pong通信を行い、片道の通信時間を計測するコード。
  - データサイズNを8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216 Bytesの順に変化させて、通信時間を計測する。
  - 通信時間の計測は、MPIの`MPI_Wtime`関数を使用して行う。
  - データサイズが小さい場合は1000回、データサイズが中程度の場合は500回、データサイズが大きい場合は100回の往復通信を行い、その平均値を片道の通信時間として算出する。
- #link(<mpi_pingpong_local.shのコード>)[mpi_pingpong_local.sh]: `mpi_pingpong.cpp`をノード内通信の条件で実行するシェルスクリプト。
  - `mpirun -N 1 -n 2`で同一ノード上の2プロセスを使用して通信を行う。
- #link(<mpi_pingpong_crossnode.shのコード>)[mpi_pingpong_crossnode.sh]: `mpi_pingpong.cpp`をノード間通信の条件で実行するシェルスクリプト。
  - `mpirun -N 2 -n 2`で別ノード上の2プロセスを使用して通信を行う。

=== 実行方法:

```bash
$ mpicxx -O3 -Wall mpi_pingpong.cpp -o mpi_pingpong
$ sbatch mpi_pingpong_local.sh
$ sbatch mpi_pingpong_crossnode.sh
```

=== 実行環境: 
- PPX (a: ppx2-[00, 01], b: ppx2-00)
- Slurmジョブスクリプト
  - #strong[ノード間通信]: (`-N 2 -n 2`)
  - #strong[ノード内通信]: (`-N 1 -n 2`)

=== 実行結果:

CSV形式で出力したものをもとに、以下のような表を作成した。

#align(center)[
  #grid(
    columns: 2,
    gutter: 1em,
    include "assets/5-2/mpi_pingpong_crossnode.typ",
    include "assets/5-2/mpi_pingpong_local.typ",
  )
]
非対数軸のグラフで両者を比較すると、以下のようになる。
#figure(
  align(center)[
    #image("assets/5-2/mpi_pingpong_comparison.pdf", alt: "MPI Ping-Pong ノード間 vs ノード内通信比較グラフ", width: 80%)
  ], caption: [MPI Ping-Pong ノード間 vs ノード内通信比較グラフ]
)

両軸対数グラフで比較すると、以下のようになる。
#figure(
  align(center)[
    #image("assets/5-2/mpi_pingpong_comparison_loglog.pdf", alt: "MPI Ping-Pong ノード間 vs ノード内通信比較グラフ (log-log)", width: 80%)
  ], caption: [MPI Ping-Pong ノード間 vs ノード内通信比較グラフ (log-log)]
)

#figure(
  align(center)[
    #image("assets/5-2/mpi_pingpong_comparison_loglinear_bandwidth_vs_size.pdf", alt: "MPI Ping-Pong ノード間 vs ノード内通信比較グラフ (log-linear)", width: 80%)
  ], caption: [MPI Ping-Pong ノード間 vs ノード内通信比較グラフ (log-linear)]
)


== 5.2 (a)(b) の考察（ノード間 vs ノード内）
<ab-の考察ノード間-vs-ノード内>

- 非対数軸グラフを見ると、概ねデータサイズの増加に伴い、通信時間が線形的に増加していることがわかる。
- 両軸対数グラフについて:
  - データサイズが小さい場合は、ノード内・ノード間通信それぞれについて概ね横ばいになっており、通信時間が固定コスト（レイテンシ）に近い状態であることがわかる。
  - データサイズが大きくなるにつれて、通信時間がデータサイズに比例して増加する傾向が見られる。これは、通信時間が固定コストを無視できるほど大きくなり、転送時間が支配的になっていることを示している。
- ノード間通信とノード内通信の比較:
  - ノード内通信の方が、レイテンシが小さいことがわかる。
  - 実験環境であるPPX上では、データサイズが大きくなり、転送時間が支配的になるに従い、両者の通信時間の差が小さくなっていく傾向が見られる。つまり、この環境においては、ノード内通信もノード間通信も、転送時間の観点では同程度の性能を持っていると考えられる。
- レイテンシとバンド幅に関しての計算は、この結果をもとに、課題4-2のセクションで行った。

== 5.2 (d) Collective（集団）通信の性能テスト
=== 実行環境: 
- PPX (ppx2-[00, 01, 02, 03])
- Slurmジョブスクリプト
  - `mpirun -N 4 -n 16`で4ノード構成の16プロセスを使用して通信を行う。

=== コードの説明:
- #link(<mpi_collective.cppのコード>)[mpi_collective.cpp]: MPIを用いて、プロセス間で以下の集団通信を行い、通信時間を計測するコード。
  - データサイズNを8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216 Bytesの順に変化させて、通信時間を計測する。
  - 通信時間の計測は、MPIの`MPI_Wtime`関数を使用して行う。
  - 集団通信の種類は、以下の4種類を実装した。
    - Manual_Bcast(手動ブロードキャスト): ルートプロセスが他のプロセスに対して、`for`ループで順番に`MPI_Send`を使用してデータを送信するブロードキャストの実装。
    - MPI_Bcast: MPIの組み込み関数`MPI_Bcast`を使用したブロードキャスト。
    - MPI_Allgather: MPIの組み込み関数`MPI_Allgather`を使用した全員集約通信。
  - 測定は、各データサイズに対して100回の通信を行い、その平均値を通信時間として算出する。
- #link(<mpi_collective.shのコード>)[mpi_collective.sh]: `mpi_collective.cpp`を実行するシェルスクリプト。
  - `mpirun -N 4 -n 16`で4ノード構成の16プロセスを使用して通信を行う。
  - プロセス数を[2 4 8 16 32 64]で変化させて、`mpi_collective.cpp`を実行するようにした。

=== 実行方法:

```bash
$ mpicxx -O3 -Wall mpi_collective.cpp -o mpi_collective
$ sbatch mpi_collective.sh
```

=== 実行結果と考察:

参考として、5.2(a)のノード間通信の結果を同時に示すと、以下のようになる。

#strong[データサイズを変化させた場合の通信時間の比較（P=16 固定）]:
#figure(
  align(center)[
    #image("assets/5-2/mpi_collective_size_vs_bandwidth.pdf", alt: "データサイズ vs 通信時間", width: 80%)
  ], caption: [集団通信 データサイズ vs 通信時間]
)

#figure(
  collective_tables.at(0)
)


#strong[データサイズ vs 通信時間に関する考察:]
- 全ての線がデータサイズが小さいうちはレイテンシの影響が大きいため「横ばい」で、ある程度大きくなったあたりから帯域の影響が大きくなり「線形的に増加」していることがわかる。
- Ping -Pong(1対1通信)と「MPI_Bcast(1対15通信)」を比較すると、データサイズが大きくなっても、通信時間の差があまり大きくなっていないことがわかる。つまり、MPI_Bcastは、単純なループで送信する手法（手動ブロードキャスト）と比べて、MPIにより、通信の効率化が図られていると考えられる。
- MPI_Allgatherは、MPI_Bcastと比べて、通信時間が大きくなっていることがわかる。これは、MPI_Allgatherは全員集約通信であるため、全プロセスが全プロセスからデータを受け取る必要があるため、通信のオーバーヘッドが大きくなっていると考えられる。単純に考えれば、通信データ量が[プロセス数]倍になるため、通信時間も[プロセス数]倍になると考えられる。
  - 実際、N=16MBの時の`MPI_Bcast`の通信時間は、約0.015秒であり、`MPI_Allgather`の通信時間は、約0.2秒であるため、通信時間の差は約13倍となっている。プロセス数が16であることを考えると、通信時間の差がプロセス数の倍数に近いことがわかる。
- グラフのデータサイズ128B付近において、「手動ブロードキャスト」と「`MPI_Bcast`」における通信時間の不連続な増加が見られる。これは、MPIの実装上で、データサイズがある程度大きくなったあたりで、通信のアルゴリズムが切り替わるなどの境界が存在している可能性があるとも考えられる。

#figure(
  align(center)[
    #image("assets/5-2/mpi_collective_procs_vs_time.pdf", width: 90%)
  ], caption: [集団通信 プロセス数 vs 通信時間]
)

#align(center)[
  - 実線(---): データサイズが1MBのときの通信時間
  - 点線(- - -): データサイズが8Bのときの通信時間
]

#figure(
  collective_tables.at(1)
)


#figure(
  collective_tables.at(2)
)

// #text(fill: red)[= ↓これ以降はまだ途中。↓]

#strong[プロセス数 vs 通信時間に関する考察:]
// TODO: 考察書く
- グラフの緑色の線（MPI_Bcast）のように、プロセス数が2から64に増えても、通信量があまり増加していないことがわかる。これは、MPI_Bcastの通信アルゴリズムが、プロセス数が増加しても、通信の効率化が図られているためであると考えられる。
- 青色の線（手動でのブロードキャスト）はプロセス数の増加に伴い、通信時間も大きくなっていることがわかる。さらに、橙色の線(MPI_Allgather)は、特にデータ量が多い場合において、タイムの悪化が見られる。
  - MPIによる効率化があっても、Allgatherのような全員集約通信は、プロセス数が増えると通信量が爆発的に増加するため、通信時間も大きくなってしまうと考えられる。

== 5.2 (e) 通信の競合テスト

=== コードの説明:

- #link(<mpi_congestion.cppのコード>)[mpi_congestion.cpp]: MPIを用いて、複数のプロセスが同時に通信を行う場合の通信時間を計測するコード。
  - データサイズNを8~16MBの範囲で変化させて、通信時間を計測する。
  - ペア通信については、例えば、プロセス数が32なら、プロセス0とプロセス16が通信を行う、プロセス1とプロセス17が通信を行う、というように、隣同士（ノード内）にならないように通信ペアを設定した。
  - 通信時間計測の前に、通信のウォームアップとして、各プロセスが1回通信を行うようにした。
  - 通信は、各データサイズに対して100回の通信を行い、その平均値を通信時間として算出する。
- #link(<mpi_congestion.shのコード>)[mpi_congestion.sh]: `mpi_congestion.cpp`を実行するシェルスクリプト。
  - `mpirun -N 4`で4ノードを使用して通信を行う。
  - プロセス数を[2 4 8 16 32]で変化させて、`mpi_congestion.cpp`を実行するようにした。

=== 実行環境:

- PPX (ppx2-[00, 01, 02, 03])

=== 実行方法:

```bash
$ mpicxx -O3 -Wall mpi_congestion.cpp -o mpi_congestion
$ sbatch mpi_congestion.sh
```

=== 実行結果:

#figure(
  align(center)[
    #image("assets/5-2/mpi_congestion_2nodes.pdf", alt: "通信時間 vs プロセス数", width: 80%)
  ], caption: [ペア通信 [バンド幅 vs プロセス数]]
) <fig:mpi-congestion-loglog>

#figure(
  align(center)[
    // mpi_congestion.typの表をここに表示
    #include "assets/5-2/mpi_congestion_2nodes.typ"
  ], 
  caption: [ペア通信の通信時間の表], 
  kind: table
) <tbl:mpi-congestion>





=== 5.2 (e) の考察

// - データサイズが小さい領域(8Bytes~数KB程度)では、通信ペア数が１ペア（２プロセス）から３２ペア（６４プロセス）に増加しても、通信時間があまり増加していないことがわかる。これは、データサイズが小さい場合は、通信のレイテンシが支配的であるため、通信ペア数の増加による影響が小さいと考えられる。
- データサイズが8Bytesのように小さい場合は、通信ペア数が1ペア（2プロセス）から32ペア（64プロセス）に増加しても、
- 一方で、1MB以上の大容量データにおいては、通信ペア数の増加に伴い、通信時間が明確に右肩上がりに増加していることがわかる。（例: 16MB通信で、1ペア時の約1.5msから、32ペア時には約23.5.msへと大幅に遅延。）
  - これは、全ペアが一斉に大容量データの通信を行おうとした結果、一度に通信できる転送帯域を超えてしまい、ネットワークの競合が発生しているためであると考えられる。
- [留意点]: 
  - @fig:mpi-congestion-loglog は両対数スケールを使用しているため、視覚的には、少量のデータサイズにおいての微小な増加が大きく見えるが、@tbl:mpi-congestion からもわかる通り絶対値（実際の通信時間）で見ると、データサイズが小さい領域では、通信ペア数の増加による通信時間の増加は、数マイクロ秒程度の微小なものであることがわかる。
- [実験上の工夫]: 
  - 実験の初期段階において、最もデータサイズの小さい8 Bytesの通信において、通信時間が16 KBの時よりも大きくなってしまうなどの結果が見られた。原因を調べたところ、MPIの仕様である初回通信時の動的なコネクション確立が関連しているのではないかと考え、時間計測前に事前通信を行うようにしたところ、通信時間の結果が安定し、綺麗な右肩上がりの傾向が見られるようになった。

// == 寄り道: Rust(Rayon)による並列化実験
// <寄り道-rustrayonによる並列化実験>
// Rustにも、C++のOpenMPやMPIのような並列処理を簡単に実装できるライブラリが存在することを知ったので、実験してみた。

// === 5.1(a) Rust(Rayon)版: 実行結果
// <a-rustrayon版-実行結果>
// #figure(
//   align(center)[#table(
//     columns: 2,
//     align: (auto,auto,),
//     table.header([実行回数], [Rust(Rayon) Task A 時間 (秒)],),
//     table.hline(),
//     [1], [0.010524],
//     [2], [0.009364],
//     [3], [0.008200],
//   )]
//   , kind: table
//   )

// === Work-strealingの体感用
// <work-strealingの体感用>
// - 三角関数ループの実装。

// - C++版: `#pragma omp parallel for` を用いてループを並列化。

//   - `/workspaces/parallel-programming-exp/unbalanced.cpp`

// - C++(schedule(dynamic))版: `#pragma omp parallel for schedule(dynamic)`
//   を用いてループを並列化。

//   - `/workspaces/parallel-programming-exp/unbalanced.cpp` （編集済み）

// - Rust(Rayon)版: `par_iter()` を用いてループを並列化。

//   - `/workspaces/parallel-programming-exp/unbalanced_rust/src/main.rs`

// ==== 実行結果
// <実行結果-1>
// #figure(
//   align(center)[#table(
//     columns: (25%, 25%, 25%, 25%),
//     align: (auto,auto,auto,auto,),
//     table.header([実行回数], [C++ (OpenMP) 時間 (秒)], [C++ (OpenMP +
//       schedule(dynamic)) 時間 (秒)], [Rust(Rayon) 時間 (秒)],),
//     table.hline(),
//     [1], [0.785564], [0.586284], [0.591402],
//     [2], [0.798154], [0.601501], [0.576145],
//     [3], [0.619695], [0.586284], [0.590889],
//   )]
//   , kind: table
//   )
// 
== 5.2測定結果を元に4.4節 課題に回答

```
[4.4節 課題]
スーパーコンピュータ Pegasus における，ノード間 MPI
通信の性能を調べ，式 (5) の a，及び b
に相当するパラメータを求めよ．同様に，ノード内のプロセッサ間で MPI
通信を行った場合についても調べよ
```

#align(center)[$T_(c o m m) = a + N / b$ … (5)]

=== 算出方法: 
- \[課題 5.2\]で行なった通信実験の結果をもとに、計算する。
- レイテンシaの推定については、データサイズNが極めて小さい領域である先端3点(8, 16, 32 Bytes)の平均値をaの値として近似する。
- バンド幅bの推定については、データサイズが十分に大きい1MB以降の点において、レイテンシが無視できると仮定して、$T_(c o m m) = N / b$と近似し、$b = frac(N, T_(c o m m))$で算出する。

（有効数字は3桁程度で表記する）

=== 計算結果:
- 計算はPythonで行った。

- ノード間(5.2 a)
// a = 9.65 * 10^(-7) = 0.97 μs
$ a approx 9.65 times 10^(-7) upright(" sec") approx 0.97 med mu s $
// b = 1.1230 * 10^9 = 11.23 GB/s
$ b approx 1.1230 times 10^9 upright(" Bytes/sec") approx 11.23 med G B\/s $

- ノード内(5.2 b)

// a = 2.80 * 10^(-7) = 0.280 μs
$ a approx 2.80 times 10^(-7) upright(" sec") approx 0.28 med mu s $
// b = 1.1056 * 10^9 = 11.06 GB/s
$ b approx 1.1056 times 10^9 upright(" Bytes/sec") approx 11.06 med G B\/s $

=== 回答まとめ
#figure(
  align(center)[#table(
    columns: 3,
    align: (auto,auto,auto,),
    table.header([環境], [レイテンシ $a$ ($mu s$)], [バンド幅 $b$ (GB/s)],),
    table.hline(),
    [ノード間 (5.2 a)], [$0.97$], [11.23],
    [ノード内 (5.2 b)], [$0.28$], [11.06],
  )],
  caption: [課題5-2の計算結果],
  kind: table
  )

実際のデータポイントと求めたa,bによる直線を両軸対数グラフでプロットすると、以下のようになる。

#figure(
  align(center)[
    #image("assets/5-2/mpi_pingpong_regression_loglog.pdf", alt: "MPI通信性能の両軸対数グラフ", width: 90%)
  ], caption: [MPI通信性能の両軸対数グラフ]
)

// 両端の２点を結んだ直線を描画すると、以下のようになる。

// （両軸対数グラフのため、直線ではないが、傾きは同じである）

// #figure(image("images/mpi_performance_loglog_graph.png", alt: "alt text"),
//   caption: [
//     alt text
//   ]
// )
=== [4.4節 課題]の考察

- ノード内通信の方が、レイテンシもバンド幅も、ノード間通信よりもわずかに優れていることがわかる。
- バンド幅については、両者とも約11 GB/sであり、ほぼ同程度の性能を持っていると考えられる。
- レイテンシについては、ノード内通信の方が約0.280 μsであるのに対し、ノード間通信は約0.97 μsであり、ノード内通信の方が約3.5倍速いことがわかる。
  - この差は、ノード間通信では物理的な距離があることや、通信経路に複数のネットワーク機器が介在することなどが原因であると考えられる。

= 課題 4： 

#strong[実験テキスト 5.4 節のハイブリッドプログラムについて，ソースを提示し，並列化の手法・工夫について解説せよ．プログラムの動きや，どういう点を考えて並列化を行ったか，速度向上に対する予測（「こうしたからここが速くなるはず」，「ここは逐次のままなので速度向上に貢献しない」など）を記述せよ．]
```
[5.4節 課題]:
(要約)
5.3節で作成したN体問題（重力相互作用）のシミュレーションプログラムを元に、MPIとOpenMPを組み合わせたハイブリッド並列プログラムを実装し、以下の点について論じよ。
・実装したハイブリッドプログラムのソースコードの提示。
・並列化の手法・工夫についての解説（プログラムの設計思想や動作の仕組み）。
・速度向上に対する論理的な予測（「OpenMPとMPIをどのように分担させたから速くなるはず」「この通信・集計処理は逐次のままなので速度向上に貢献しない（アムダールの法則）」などの考察）。
```

== 実装コード

=== `nbody_hybrid.cpp`

```cpp
#include <mpi.h>
#include <omp.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <vector>

// ../file_util/read_double_file.hppから、ファイルからdoubleの配列を読み込む関数をインクルード
#include "../file_util/read_double_file.hpp"


struct Particle {
	double mass;
	double x, y, z;
	double vx, vy, vz;
};

int main(int argc, char** argv) {
	MPI_Init(&argc, &argv); // MPIの初期化

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank); // 自分のランク（プロセスID）を取得
  MPI_Comm_size(MPI_COMM_WORLD, &size); // 全プロセスの数を取得

  // 引数が足りない場合はエラーを出して終了
  if (argc < 10) {
    if (rank == 0) {
      std::fprintf(stderr, "Usage: %s N nodes m_path x_path y_path z_path vx_path vy_path vz_path\n", argv[0]);
    }
    MPI_Finalize();
    return 1;
  }

  // コマンドライン引数があればNとして読み込み、無ければデフォルト10000にする
	int N = 10000;
	if (argc > 1) {
		N = std::atoi(argv[1]);
	}

  // コマンドライン引数からファイルパスを読み込む
  // nodesは二番目の引数
  const int nodes = std::atoi(argv[2]);
  
  const char* m_path = argv[3]; 
  const char* x_path = argv[4]; 
  const char* y_path = argv[5]; 
  const char* z_path = argv[6];
  const char* vx_path = argv[7];
  const char* vy_path = argv[8];
  const char* vz_path = argv[9];


	const int STEPS = 1000; // ステップ数
	const double DT = 1.0; // タイムステップ
	const double G = 1.0; // 万有引力定数


	const int omp_threads = omp_get_max_threads();

  
  // 各プロセスの担当する星の数を計算
	const int local_particle_count = N / size; // 割り切れることにする
  if (N % size != 0) {
    if (rank == 0) {
      std::fprintf(stderr, "N must be divisible by MPI process count: N=%d, size=%d\n", N, size);
    }
    MPI_Finalize();
    return 1;
  }
	const int start_index = rank * local_particle_count;
	const int end_index = start_index + local_particle_count;

  std::vector<Particle> particles(N); // 全ての星の情報を全プロセスで共有するためのベクトル

	if (rank == 0) {
  std::vector<double> masses = read_double_file(m_path, static_cast<std::size_t>(N));
  std::vector<double> xs = read_double_file(x_path, static_cast<std::size_t>(N));
  std::vector<double> ys = read_double_file(y_path, static_cast<std::size_t>(N));
  std::vector<double> zs = read_double_file(z_path, static_cast<std::size_t>(N));
  std::vector<double> vxs = read_double_file(vx_path, static_cast<std::size_t>(N));
  std::vector<double> vys = read_double_file(vy_path, static_cast<std::size_t>(N));
  std::vector<double> vzs = read_double_file(vz_path, static_cast<std::size_t>(N));

    // 読み込んだサイズがNと一致するか確認
    if (masses.size() != static_cast<std::size_t>(N) ||
        xs.size() != static_cast<std::size_t>(N) ||
        ys.size() != static_cast<std::size_t>(N) ||
        zs.size() != static_cast<std::size_t>(N) ||
        vxs.size() != static_cast<std::size_t>(N) ||
        vys.size() != static_cast<std::size_t>(N) ||
        vzs.size() != static_cast<std::size_t>(N)) {
      std::fprintf(stderr, "file size does not match N: %s\n", m_path);
      MPI_Finalize();
      return 1;
    }

    // 読み込んだデータをparticlesにコピー
    for (int i = 0; i < N; ++i) {
      particles[i].mass = masses[i];
      particles[i].x = xs[i];
      particles[i].y = ys[i];
      particles[i].z = zs[i];
      particles[i].vx = vxs[i];
      particles[i].vy = vys[i];
      particles[i].vz = vzs[i];
    }
	}

  // 全プロセスで初期データを共有する
	MPI_Bcast(particles.data(), N * sizeof(Particle), MPI_BYTE, 0, MPI_COMM_WORLD);

  // 全プロセスが初期データの受け取りを終えるまで待つ
	MPI_Barrier(MPI_COMM_WORLD);

  // 初期状態を保存
  std::vector<Particle> initial_particles = particles;
  std::vector<double> run_times(3);

  // 3回実行してタイミングを計測
  for (int run = 0; run < 3; ++run) {
    // 各実行の初めに初期状態に戻す
    particles = initial_particles;

    // 時間計測開始
    const double start_time = MPI_Wtime();

    // シミュレーションのメインループ
    for (int step = 0; step < STEPS; ++step) {
		std::vector<Particle> next_particles = particles;

    #pragma omp parallel for default(none) shared(particles, next_particles, N, start_index, end_index, DT, G)
		for (int i = start_index; i < end_index; ++i) {
			double ax = 0.0;
			double ay = 0.0;
			double az = 0.0;

			for (int j = 0; j < N; ++j) {
				if (i == j) {
					continue;
				}

				const double dx = particles[j].x - particles[i].x;
				const double dy = particles[j].y - particles[i].y;
				const double dz = particles[j].z - particles[i].z;
				const double dist2 = dx * dx + dy * dy + dz * dz + 1e-10;
				const double dist = std::sqrt(dist2);
				const double f = G * particles[j].mass / dist2;

				ax += f * dx / dist;
				ay += f * dy / dist;
				az += f * dz / dist;
			}

      // 速度と位置の更新
			next_particles[i].vx = particles[i].vx + DT * ax;
			next_particles[i].vy = particles[i].vy + DT * ay;
			next_particles[i].vz = particles[i].vz + DT * az;

			next_particles[i].x = particles[i].x + DT * next_particles[i].vx;
			next_particles[i].y = particles[i].y + DT * next_particles[i].vy;
			next_particles[i].z = particles[i].z + DT * next_particles[i].vz;
		}

    // 結果の集約(Allgatherで行う)
    // MPI_Allgather(送るデータの先頭アドレス, 送るデータのサイズ, データの型, 受け取るデータの先頭アドレス, 受け取るデータのサイズ, データの型, コミュニケータ)
    MPI_Allgather(&next_particles[start_index], local_particle_count * static_cast<int>(sizeof(Particle)), MPI_BYTE,
              particles.data(), local_particle_count * static_cast<int>(sizeof(Particle)), MPI_BYTE, MPI_COMM_WORLD);
    // 共有されている変数particlesを全てのプロセスで更新する
	  }

	  MPI_Barrier(MPI_COMM_WORLD); // 全プロセスが計算を終えるまで待つ

    // 時間計測終了
    const double end_time = MPI_Wtime();
    run_times[run] = end_time - start_time;
  }

  // 平均時間を計算
  double total_time = 0.0;
  for (int i = 0; i < 3; ++i) {
    total_time += run_times[i];
  }
  double avg_time = total_time / 3.0;

  // 結果の出力
	if (rank == 0) {
		// CSV形式の計時結果（平均値）
		std::printf("%d,%d,%d,%d,%.6f\n", nodes, size, omp_threads, N,
						avg_time);
		std::ofstream outx("output_x.double", std::ios::binary);
		std::ofstream outy("output_y.double", std::ios::binary);
		std::ofstream outz("output_z.double", std::ios::binary);
		
		for (int i = 0; i < N; ++i) {
			double x = particles[i].x;
			double y = particles[i].y;
			double z = particles[i].z;
			outx.write(reinterpret_cast<const char*>(&x), sizeof(double));
			outy.write(reinterpret_cast<const char*>(&y), sizeof(double));
			outz.write(reinterpret_cast<const char*>(&z), sizeof(double));
		}
		outx.close();
		outy.close();
		outz.close();
	}

	MPI_Finalize(); // MPIの終了
	return 0;
}
```

=== `nbody_hybrid.sh`
```sh
#!/bin/bash
#set -euo pipefail

#SBATCH -J nbody_hybrid
#SBATCH -N 4
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-03]
#SBATCH --ntasks=112     # 全ノードの合計コア数（スロット）を最大112として確保
#SBATCH -o out/nbody_hybrid_%j.out

module load openmpi


echo "Nodes,MPI_Processes,OpenMP_Threads,NumParticles,Time_sec"

# 実行用のヘルパー関数を定義（引数: ノード数, MPIプロセス数, OMPスレッド数）
run_exp() {
    local nodes=$1
    # --map-by ppr:X:node:PE=N は 1ノードあたりXプロセス、1プロセスあたりNコアを割当
    local procs_per_node=$2
    local omp_threads=$3
    local run_particles=$4
    local source_particles=$5
    local data_dir="./grav_data/n${source_particles}"

    export OMP_NUM_THREADS=${omp_threads}
    export OMP_PROC_BIND=${OMP_PROC_BIND:-close}
    export OMP_PLACES=${OMP_PLACES:-cores}
    # -n は全体のMPIプロセス数
    local mpi_procs=$((nodes * procs_per_node))  # 全体のMPIプロセス数

    # 1 rank/node かつ多数スレッド時は、ソケット跨ぎの core bind エラーを回避する。
    if [[ ${procs_per_node} -eq 1 && ${omp_threads} -ge 27 ]]; then
        mpirun -n ${mpi_procs} \
            ${NQSII_MPIOPTS:-} \
            -x OMP_NUM_THREADS \
            -x OMP_PROC_BIND \
            -x OMP_PLACES \
            --map-by ppr:${procs_per_node}:node \
            --bind-to none \
            --report-bindings \
            ./nbody_hybrid \
            ${run_particles} \
            ${nodes} \
            ${data_dir}/m.double \
            ${data_dir}/x.double \
            ${data_dir}/y.double \
            ${data_dir}/z.double \
            ${data_dir}/vx.double \
            ${data_dir}/vy.double \
            ${data_dir}/vz.double
    else
        mpirun -n ${mpi_procs} \
            ${NQSII_MPIOPTS:-} \
            -x OMP_NUM_THREADS \
            -x OMP_PROC_BIND \
            -x OMP_PLACES \
            --map-by ppr:${procs_per_node}:node:PE=${omp_threads} \
            --bind-to core \
            --report-bindings \
            ./nbody_hybrid \
            ${run_particles} \
            ${nodes} \
            ${data_dir}/m.double \
            ${data_dir}/x.double \
            ${data_dir}/y.double \
            ${data_dir}/z.double \
            ${data_dir}/vx.double \
            ${data_dir}/vy.double \
            ${data_dir}/vz.double
    fi
}

# run_exp 1 28 1 896 1000

run_particles_list=(896 2688 8960 26880)
source_particles_list=(1000 3072 10000 30720)
# run_particles_list=(896)
# source_particles_list=(1000)

for idx in "${!run_particles_list[@]}"; do
    run_particles=${run_particles_list[$idx]}
    source_particles=${source_particles_list[$idx]}

    # １ノード
    run_exp 1 28 1 "${run_particles}" "${source_particles}"
    run_exp 1 4 7 "${run_particles}" "${source_particles}"
    run_exp 1 2 14 "${run_particles}" "${source_particles}"
    run_exp 1 1 28 "${run_particles}" "${source_particles}"

    # ２ノード
    run_exp 2 28 1 "${run_particles}" "${source_particles}"
    run_exp 2 4 7 "${run_particles}" "${source_particles}"
    run_exp 2 2 14 "${run_particles}" "${source_particles}"
    run_exp 2 1 28 "${run_particles}" "${source_particles}"

    # ４ノード
    run_exp 4 28 1 "${run_particles}" "${source_particles}"
    run_exp 4 4 7 "${run_particles}" "${source_particles}"
    run_exp 4 2 14 "${run_particles}" "${source_particles}"
    run_exp 4 1 28 "${run_particles}" "${source_particles}"

    # 28コア全開 vs 27コア (OS Jitter回避)
    run_exp 1 1 27 "${run_particles}" "${source_particles}"
    run_exp 2 1 27 "${run_particles}" "${source_particles}"
    run_exp 4 1 27 "${run_particles}" "${source_particles}"
done
```

== ハイブリッドな並列化の手法と工夫点

=== 並列化の手法
- MPIを用いて、全プロセスで全ての星の情報を共有する。
  - 各プロセスは、全ての星の位置と速度を保持する。
  - 各ブロセスが、全星のリストの中で、自分が担当する星の範囲を決める。
  - 各プロセスは、担当する星の加速度計算と位置・速度の更新を行う。
  - 各ステップの最後に、MPI_Allgatherを用いて、全プロセスが担当する星の更新結果を全プロセスで共有する。
- OpenMPを用いて、各プロセス内で担当する星の加速度計算と位置・速度の更新を並列化する。
  - `#pragma omp parallel for` を用いて、担当する星のループを並列化する。
  - 各プロセス内で、複数のスレッドが同時に担当する星の加速度計算と位置・速度の更新を行う。

=== 工夫点
- OpenMPによる並列化(`#pragma omp parallel for`)は、各プロセスが担当する星のループを並列化するために、二重ループのうち、外側のループを並列化するようにした。これによって、各スレッドが担当する星の範囲を分担して計算することができる。外側のループと内側のループの間で、各スレッドが計算した加速度を格納する変数(ax, ay, az)をスレッドごとのローカル変数として独立させ、書き込み先となる`next_particles[i]`への更新は、スレッド間の競合を防ぎたいという意図を持って、ループの最後に行うようにした。
- 毎ステップの更新結果を他プロセスに共有する際に、`MPI_Allgather`を用いて、全員の`particles`配列を一括更新している。
  - 今回の実装では、計算対象の粒子数(`N`)がプロセス数(`size`)で割り切れることを前提として、各プロセスが担当する粒子の範囲を均等に分割している。これによって、`MPI_Allgather`で全プロセスが同じサイズのデータを送受信することができる。
  - `MPI_Allgatherv`を用いれば、粒子数がプロセス数で割り切れない場合でも、各プロセスが担当する粒子の数を柔軟に変えることができるが、通信量が不均等になるため、今回は割り切れる前提で実装している。
    - もし割り切れないことを考慮するなら、配列を長めに確保して、担当する粒子数が少ないプロセスは余った部分を使わないようにするなどの工夫も考えられる。
- ジョブスクリプト側の工夫: 
  - `--bind-to core`と`--map-by ppr:${procs_per_node}:node:PE=${omp_threads}`によって、例えば、４プロセス７スレッドの時は、`:PE=7`でMPIが１プロセスにつき、７つの物理コアをセットにしたまとまりに対して、各プロセスを縛り付ける(bind-to core)ようにしている。これによって、スレッドが物理コアを跨いで実行されることを防いでいる。
  - ただ、MPIプロセス数が1プロセスで、OpenMPスレッド数が28の時は、全てのコアを1プロセスが使用することになるため、同様のコード実装だとCPUソケットが14コアで分断されているため、ソケット跨ぎのcore bindエラーが発生する。これを回避するために、`--bind-to none` として、MPIプロセスのバインドを解除して、OpenMP側の変数 `OMP_PROC_BIND` と `OMP_PLACES` を用いて、28スレッドを全てのコアに均等に割り当てるようにしている。
  - `--report-bindings`をつけて、並列化が綺麗に分散できているかの確認をした。

=== 速度向上に対する予測

- 重力相互作用の計算は、二重ループであるため、$O(N^2)$の計算量を持つ最大のボトルネックであり、ここをOpenMPで並列化し、かつ、担当範囲をMPIプロセスで分割(`local_particle_count = N / size`)することで、純粋な計算時間に関しては、「ノード数とスレッド数の積に比例して、理想的には速度向上するはず」と予測できる。
- ただし、MPIプロセス間での通信(`MPI_Allgather`)は、全プロセスが全ての粒子の更新結果を共有するために、プロセス数を増やすほどデータ集約の連携コストが増えるため、プロセス数を増やすほど通信オーバーヘッドが大きくなり、速度向上に対する貢献が減少することが予測される。
- したがって、ノード数を増やした際のスケーラビリティは、「$O(N^2)$で減っていく計算時間」と「$O(N)$もしくは$log(P)$で増えていく通信時間」のトレードオフで決まると考えられる。粒子数$N$が小さい場合は、通信時間の割合が相対的に大きくなり、速度向上が頭打ちになるが、`N`が大き区なるほど、計算の並列化による恩恵が大きくなり、理論値に近い速度向上が期待できると予測される。

// == 5.4 重力プログラミング(N体問題)
// <重力プログラミングn体問題>
// - #strong[実行環境]: PPX, 2ノードに8プロセスを配置 (`-N 2 -n 8`)
// - #strong[条件]:
//   - OpenMP: Static / Dynamic スケジューリング
//   - MPI: 4プロセス並列 (`-np 4`)
// - #strong[試行回数]: 各 $N$ に対して 3回実行した平均値

// === 計測結果 (単位: 秒)
// <計測結果-単位-秒>
// #figure(
//   align(center)[#table(
//     columns: 4,
//     align: (auto,auto,auto,auto,),
//     table.header([Particles ($N$)], [OpenMP (Static)], [OpenMP
//       (Dynamic)], [MPI (4-proc)],),
//     table.hline(),
//     [#strong[1000]], [0.012989], [0.005777], [0.004749],
//     [#strong[5000]], [0.084548], [0.071633], [0.125297],
//     [#strong[10000]], [0.325343], [0.284311], [0.504013],
//     [#strong[20000]], [1.218463], [1.241327], [1.990713],
//   )]
//   , kind: table
//   )

= 課題 5： 
#strong[課題 4 のプログラムについて，ノード数とスレッド数の様々な組み合わせの実行結果を示し，速度向上率，並列化効率を求めよ．さらに，結果に対する考察を示せ．]

実行結果として、以下のグラフと表を示す。
- #link(<graph:nbody-hybrid-time>)[N固定で、ノード数とスレッド数の組み合わせを変化させた時の実行時間のグラフ(各Nごとに計4グラフ)]
- #link(<graph:nbody-hybrid-speedup>)[N固定で、ノード数とスレッド数の組み合わせを変化させた時の速度向上率のグラフ(各Nごとに計4グラフ)]
- #link(<graph:nbody-hybrid-efficiency>)[N固定で、ノード数とスレッド数の組み合わせを変化させた時の並列化効率のグラフ(各Nごとに計4グラフ)]
- #link(<graph:nbody-hybrid-speedup-1mpi28omp>)[スレッド数固定で、ノード数とデータサイズNを変化させた時の速度向上率のグラフ(1MPI×28OMPの実行結果)]
- #link(<graph:nbody-hybrid-efficiency-1mpi28omp>)[スレッド数固定で、ノード数とデータサイズNを変化させた時の並列化効率のグラフ(1MPI×28OMPの実行結果)]
- #link(<graph:nbody-hybrid-gips>)[ノード数固定で、データサイズとスレッド数を変化させた時の計算性能GIPSのグラフ(4ノードでの実行結果)]
- #link(<tbl:nbody-hybrid>)[ノード数とスレッド数の様々な組み合わせの実行時間・速度向上率・並列化効率の表]

== 実行結果

=== 実行時間のスケーラビリティのグラフ

// 複数枚のPDFの時のグラフの表示方法
#figure(
  grid(
    columns: 2,
    gutter: 1em,
    figure(
      image("assets/5-4/nbody_hybrid_896.pdf", page: 1),
      caption: [N=896]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_2688.pdf", page: 1),
      caption: [N=2688]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_8960.pdf", page: 1),
      caption: [N=8960]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_26880.pdf", page: 1),
      caption: [N=26880]
    ),
  ),
  caption: [N=896, 2688, 8960, 26880の時の実行時間のスケーラビリティグラフ一覧]
)<graph:nbody-hybrid-time>

=== 速度向上率のグラフ

#figure(
  grid(
    columns: 2,
    gutter: 1em,
    figure(
      image("assets/5-4/nbody_hybrid_896.pdf", page: 2),
      caption: [N=896]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_2688.pdf", page: 2),
      caption: [N=2688]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_8960.pdf", page: 2),
      caption: [N=8960]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_26880.pdf", page: 2),
      caption: [N=26880]
    ),
  ),
  caption: [N=896, 2688, 8960, 26880の時の速度向上率グラフ一覧]
)<graph:nbody-hybrid-speedup>

=== 並列化効率のグラフ

#figure(
  grid(
    columns: 2,
    gutter: 1em,
    figure(
      image("assets/5-4/nbody_hybrid_896.pdf", page: 3),
      caption: [N=896]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_2688.pdf", page: 3),
      caption: [N=2688]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_8960.pdf", page: 3),
      caption: [N=8960]
    ),
    figure(
      image("assets/5-4/nbody_hybrid_26880.pdf", page: 3),
      caption: [N=26880]
    ),
  ),
  caption: [N=896, 2688, 8960, 26880の時の並列化効率グラフ一覧]
)<graph:nbody-hybrid-efficiency>

=== ノード数を変化させた時の速度向上率のグラフ

#figure(
  align(center)[
    #image("assets/5-4/nbody_hybrid_26880.pdf", page: 5, width: 80%)
  ],
  caption: [ノード数を変化させた時の速度向上率$S(p)$のグラフ(1MPI×28OMPの実行結果) ]
)<graph:nbody-hybrid-speedup-1mpi28omp>

=== ノード数を変化させた時の並列化効率のグラフ

#figure(
  align(center)[
    #image("assets/5-4/nbody_hybrid_26880.pdf", page: 6, width: 80%)
  ],
  caption: [Nを変化させた時の並列化効率$E(p)$のグラフ(1MPI×28OMPの実行結果) ]
)<graph:nbody-hybrid-efficiency-1mpi28omp>

=== 計算性能GIPSのグラフ

#figure(
  align(center)[
    #image("assets/5-4/nbody_hybrid_26880.pdf", page: 4, width: 80%)
  ],
  caption: [Nを変化させた時の計算性能GIPSのグラフ(4ノードでの実行結果)]
)<graph:nbody-hybrid-gips>



=== 実行時間・速度向上率・並列化効率の表

#figure(
  align(center)[
    #include "assets/5-4/nbody_hybrid.typ"
  ],
  caption: [nbody_hybrid の実行時間・速度向上率・並列化効率・実効性能 [GIPS]],
  kind: table
) <tbl:nbody-hybrid>

== 考察

- 基本的に、通信過多になる[28MPIプロセス×1スレッド]が最も遅く、通信を最小化する[1MPIプロセス×28スレッド]が最も速い傾向が見られる。これは、通信オーバーヘッドが大きいほど、速度向上に対する貢献が減少するという予測と一致している。
  - しかし、１ノード実行時において、4MPIプロセス×7スレッドが、1MPIプロセス×28スレッドとほぼ同等の性能を示しているケースも見られた。これは、プロセスを分割したことで、1プロセス内で28スレッドを立てた時に、発生するソケット跨ぎが回避され、４MPIに分割したことによって得られたNUMA(ローカルメモリアクセス)の恩恵が、通信オーバーヘッドの増加を相殺している可能性があると考える。
-  1ノード（1MPI×28OMP）のデータを見ると \
  - $N=896$: 0.308 s\
  - $N=2688$ (約3倍): 2.19 s （理論上は $0.308 times 3^2 = 2.77 s$）\
  - $N=8960$ (10倍): 23.61 s （理論上は $0.308 times 10^2 = 30.8 s$）\
  - $N=26880$ (30倍): 211.3 s （理論上は $0.308 times 30^2 = 277 s$）\ 
  というように、ある程度は$O(N^2)$に近いスケーリングが見られる。\
  理論値よりも実測が早いのは、Nが大きくなると、計算時間が長くなり、通信やスレッドの管理などのオーバーヘッドの影響が小さくなるためであると考える。
- #link(<graph:nbody-hybrid-efficiency-1mpi28omp>)[並列化効率のグラフ]のように、
  - Nがが小さいとノード間通信のオーバーヘッドの影響が大きく、アムダールの法則にしたがって、効率が急降下する傾向が見られる。
  - 一方でNを大きくしていくと、計算量$O(N^2)$が通信量$O(N)$を圧倒するようになり、ノード数を増やすことの恩恵が大きくなり、#link(<tbl:nbody-hybrid>)[総合表]のN=26880の行のように、4ノードでも、99%という非常に高い効率が得られるようになっている。
- #link(<graph:nbody-hybrid-speedup-1mpi28omp>)[速度向上率のグラフ]を見ると、Nが十分に大きい時、ノード数を２倍、４倍にすると、実行時間がほぼ半分、1/4になっていることがわかる。これも、計算量$O(N^2)$が通信量$O(N)$を圧倒するようになっているためであると考える。
- 速度向上率 $S(p)$ および並列化効率 $E(p)$ は、各実行パターンにおいて28コアをフル活用した『1ノード実行時』を基準として算出した。

= 課題 6：
#strong[実験全体を通して得られた事項についてまとめよ．例えば，並列化手法に対する考え，プログラムの実行時間と通信時間との関係など，気がついたことを述べよ．最後にこの実験を通して得られた自分なりの結論をまとめよ．]

== 並列化手法とハードウェアアーキテクチャに対する考察

- 本実験全体を通して、高性能計算（HPC）における並列化手法は、単に計算タスクを分割するだけではなく、背後にあるハードウェアの物理的制約（トポロジ）と密接に調和させる必要があることが明確になった。
- MPIを用いた分散メモリ型並列化は、ノード間を跨いだ大規模な拡張性を可能にする一方で、ネットワークの物理帯域（バイセクション・バンド幅）という絶対的な上限が存在する。課題3の通信競合実験では、プロセス数の増加に伴い全ペアの合計バンド幅が約11 GB/s付近でサチュレート（頭打ち）する様子が観測され、通信プロセスを不用意に増やすことの危険性が実証された。
- 一方、OpenMPによる共有メモリ型並列化と組み合わせたハイブリッド手法（課題5）では、ノード内においてNUMA（Non-Uniform Memory Access）アーキテクチャの特性が顕著に表れた。
- 1ノード実行時には、プロセスを分割しローカルメモリアクセスを最適化した「4MPI×7スレッド」の手法が、通信が皆無であるはずの「1MPI×28スレッド」と同等の性能を叩き出した。しかし、複数ノードに拡張した途端にノード間通信のオーバーヘッドが支配的となり、最終的には通信参加プロセス数を極限まで減らした「1MPI×28スレッド」が最強のスケーラビリティを示した。これは、共有メモリと分散メモリのトレードオフを正確に把握することの重要性を示している。

== 実行時間と通信時間の関係（問題サイズへの依存性）
- 並列プログラムにおける「計算」と「通信」のバランスは、問題サイズ $N$ によって劇的に変化することが確認された。
- N体問題のように計算量が $O(N^2)$、通信量が $O(N)$ で増加するアルゴリズムにおいて、$N$ が小さい領域では通信のレイテンシや初期化オーバーヘッドが支配的となり、並列化効率はアムダールの法則に従って急降下する。しかし、$N$ を極大化させると計算量の比重が圧倒的になり、ノード間通信のコストを相対的に隠蔽できるため、高い並列化効率（GIPS）を維持したままスケールさせることができた。これは計算機科学における「グスタフソンの法則」を実データで証明するものであり、スパコンの真価は大容量の演算においてのみ発揮されることが定量的に確認できた。

== 本実験を通して得られた結論
- 本実験を通した最大の結論は、**「スーパーコンピュータのピーク性能を引き出すためには、アルゴリズムの数学的最適化のみならず、OSやミドルウェアの挙動を完全に支配・制御しなければならない」**ということである。
- 課題3で観測されたプロトコルの切り替え（Eager vs Rendezvous）による中間領域でのオーバーヘッドや、課題5におけるOS Jitter（ノイズ）の影響、そしてジョブスクリプトにおける明示的なCPUコアのバインディング（`bind-to core` と `none` の使い分け）など、ソフトウェアとハードウェアの境界で起きる現象が実行時間に多大な影響を与えていた。
- 並列プログラミングとは、単なるコードの記述ではなく、演算コア、キャッシュ、NUMAノード、そして InfiniBand 等のネットワークという「物理的な計算資源」の挙動を予測し、ボトルネックを設計によって回避する「システムエンジニアリング」そのものであると結論づける。

= ソースコード

// 数値的な結果（時間測定の評価結果等）については，データを表，及びグラフの両方で示すこ
// と．但し，データ数が少なくグラフにするのが適当でないようなものについては，表のみで良い．
// また，測定に用いたプログラムは全て記述すること．但し，文中に差し込むのではなく，レポート
// の末尾に付録として添付し，各プログラムに番号をつけ，本文中ではその番号を参照しながら対応
// 付けを行うこと．
// 
== 課題2のソースコード

- #link(<openmp_tasks.cppのコード>)[openmp_tasks.cpp]
- #link(<openmp_tasks.shのコード>)[openmp_tasks.sh]

// `openmp_tasks.cpp`のコードをここに記載する。

=== openmp_tasks.cpp
<openmp_tasks.cppのコード>

```cpp
#include <iostream>
#include <vector>
#include <cmath>
#include <omp.h>

// 時間計測用ヘルパー関数 (OpenMP仕様)
double get_time() {
    return omp_get_wtime();
}

// (a) 配列データの総和を求めよ (整数)
void task_a_int(int n, const std::vector<int>& data) {
    int sum = 0;
    double start = get_time();

    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < n; i++) {
        sum += data[i];
    }

    double end = get_time();

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
    
    std::cout << "C, " << omp_get_max_threads() << ", " << m << "x" << n << ", " << end - start << std::endl;
}
int main() {
    // --- 検証するデータサイズのリスト ---
    // Task A, B用
    std::vector<int> sizes_A_Int_and_B = {10, 1000, 1000000, 10000000, 100000000};
    std::vector<int> sizes_A_float = {10, 1000, 1000000, 10000000, 100000000};
    
    // Task C用
    std::vector<int> sizes_C = {10, 100, 500, 1000};

    for (int n : sizes_A_Int_and_B) {
        std::vector<int> data_a(n, 1); // データ確保
        task_a_int(n, data_a);
    }

    for (int n : sizes_A_float) {
        std::vector<float> data_a(n, 1.0f); // データ確保
        task_a_float(n, data_a);
    }

    for (int n : sizes_A_Int_and_B) {
        task_b(n);
    }

    for (int size : sizes_C) {
        int m = size, k = size, n = size;
        std::vector<std::vector<double>> A(m, std::vector<double>(k, 1.0)); // Aを1で初期化
        std::vector<std::vector<double>> B(k, std::vector<double>(n, 1.0)); // Bを1で初期化
        std::vector<std::vector<double>> C(m, std::vector<double>(n, 0.0)); // Cを0で初期化
        task_c(m, k, n, A, B, C);
    }

    return 0;
}
```

=== openmp_tasks.sh
<openmp_tasks.shのコード>

これのみ、`.sh`で平均化しているが、これ以降は、`.cpp`内で平均化するようにした。

```sh
#!/bin/bash
#SBATCH -J openmp_test       # ジョブの名前（自分でわかりやすい名前）
#SBATCH -N 1                 # 使用するノード数（OpenMPは1ノード内で完結させるので1）
#SBATCH -n 1                 # タスク数（MPIプロセスの数。今回はOpenMPだけなので1）
#SBATCH -c 28                # 1タスクあたりのコア数（スレッド数）
#SBATCH -o out/openmp_tasks_%j.out        # 実行結果の保存先（%j は自動的に割り当てられるジョブIDの数字に変わる）
#SBATCH -p ppx2
#SBATCH -w ppx2-00

# Slurmが確保してくれたコア数を、OpenMPのスレッド数として環境変数にセットする
# 2の累乗で増やしつつ、物理限界（28）とその直前（24）を観測し、その後オーバーヘッド（32〜）を観測する
THREADS=(1 2 4 8 16 24 28 32 64 128)
# THREADS=(1 2)
RUNS=2

AVG_CSV="out/openmp_tasks_avg.csv"

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
```

== 課題2のソースコード
- 5.2 (a)(b) のソースコード
  - #link(<mpi_pingpong.cppのコード>)[mpi_pingpong.cpp]
  - #link(<mpi_pingpong_local.shのコード>)[mpi_pingpong_local.sh]
  - #link(<mpi_pingpong_crossnode.shのコード>)[mpi_pingpong_crossnode.sh]
- 5.2 (d) のソースコード
  - #link(<mpi_collective.cppのコード>)[mpi_collective.cpp]
  - #link(<mpi_collective.shのコード>)[mpi_collective.sh]
- 5.2 (e) のソースコード
  - #link(<mpi_congestion.cppのコード>)[mpi_congestion.cpp]
  - #link(<mpi_congestion.shのコード>)[mpi_congestion.sh]


=== 5.2 (a)(b) のソースコード

==== mpi_pingpong.cpp
<mpi_pingpong.cppのコード>

```cpp
#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
  // MPIの初期化(全員が個室に入るイメージ)
  MPI_Init(&argc, &argv);

  int rank, size;

  // 自分が何番目のプロセス（個室）かを取得
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // 全体でいくつのプロセスがあるかを取得
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  // Ping-Pongは２者間で行うので、プロセス数が2でない場合はエラー
  if (size != 2) {
    if (rank == 0) {
      std::cerr << "Error: This program requires exactly 2 processes." << std::endl;
    }
    MPI_Finalize(); // MPIの終了(全員が個室から出るイメージ)
    return 1;
  }

  const std::size_t MIN_BYTES = 8;
  const std::size_t MAX_BYTES = 16 * 1024 * 1024; // 16 MB
  const int WARMUP_ITERATIONS = 10;

  if (rank == 0) {
    std::cout << "DataSize_Bytes,Time_sec" << std::endl;
  }

  for (std::size_t data_bytes = MIN_BYTES; data_bytes <= MAX_BYTES; data_bytes <<= 1) {
    int count = static_cast<int>(data_bytes / sizeof(double));

    // 条件に合わせて、各サイズで 100〜1000 回の往復を行う
    int num_iterations = 100;
    if (data_bytes <= 64 * 1024) {
      num_iterations = 1000;
    } else if (data_bytes <= 1024 * 1024) {
      num_iterations = 500;
    }

    // 送受信用のデータ箱を用意
    std::vector<double> data(count, 1.0);

    MPI_Barrier(MPI_COMM_WORLD); // 全プロセスがここまで来るのを待つ

    // 初回の影響を減らすため軽くウォームアップ
    for (int i = 0; i < WARMUP_ITERATIONS; i++) {
      if (rank == 0) {
        MPI_Send(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD);
        MPI_Recv(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      } else if (rank == 1) {
        MPI_Recv(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Send(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
      }
    }

    MPI_Barrier(MPI_COMM_WORLD);

    // 時間計測開始
    double start_time = MPI_Wtime();
    for (int i = 0; i < num_iterations; i++) {
      if (rank == 0) {
        // プロセス0がプロセス1にデータを送る
        // MPI_Send(送るデータ, 要素数, 型, 宛先, タグ, コミュニケータ)
        MPI_Send(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD);
        // プロセス1からの返信を待つ
        // MPI_Recv(受け取る変数, 要素数, 型, 送り主, タグ, コミュニケータ, ステータス)
        MPI_Recv(data.data(), count, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      } else if (rank == 1) {
        // プロセス1がプロセス0からデータを受け取る
        MPI_Recv(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        // プロセス0にデータを返信する
        MPI_Send(data.data(), count, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
      }
    }
    // 時間計測終了
    double end_time = MPI_Wtime();

    if (rank == 0) {
      // 往復時間(Ping-Pong)の合計を、回数*2 で割り、片道(Tcomm)の時間を算出
       double time_per_half_trip = (end_time - start_time) / (2.0 * num_iterations);
      std::cout << data_bytes << "," << time_per_half_trip << std::endl;
    }
  }

  // 最後全員で退出
  MPI_Finalize();
  return 0;
}
```

==== mpi_pingpong_local.sh
<mpi_pingpong_local.shのコード>

```sh
#!/bin/bash
#SBATCH -J mpi_pingpong_local      # ジョブ名
#SBATCH -p ppx2
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --nodelist=ppx2-00
#SBATCH -o out/mpi_pingpong_local_%j.out        # 結果の出力

# 実行時にもMPI環境をロードする必要がある
module load openmpi

# mpirun実行 (-npを書かなくても、Slurmの -n 2 の指示を自動で読み取って2プロセス立ち上げます)
mpirun ./mpi_pingpong
```

==== mpi_pingpong_crossnode.sh
<mpi_pingpong_crossnode.shのコード>

```sh
#!/bin/bash
#SBATCH -J mpi_pingpong_crossnode      # ジョブ名
#SBATCH -p ppx2
#SBATCH -N 2
#SBATCH -n 2
#SBATCH --ntasks-per-node=1
#SBATCH --nodelist=ppx2-00,ppx2-01
#SBATCH -o out/mpi_pingpong_crossnode_%j.out        # 結果の出力

# 実行時にもMPI環境をロードする必要がある
module load openmpi

# mpirun実行 (-npを書かなくても、Slurmの -n 2 の指示を自動で読み取って2プロセス立ち上げます)
mpirun ./mpi_pingpong
```

=== 5.2 (d) のソースコード

==== mpi_collective.cpp
<mpi_collective.cppのコード>

```cpp
#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank); // (memo) 各プロセス君に対して、自分が何番であるかを教えて、rankに保存する
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // 集団通信の違いを見るため、最低でも3プロセス以上での実行
    if (size < 2) {
        if (rank == 0) std::cerr << "Error: Requires at least 2 processes." << std::endl;
        MPI_Finalize(); return 1;
    }

    const int NUM_ITERATIONS = 100;
    const int MIN_BYTES = 8;
    const int MAX_BYTES = 16 * 1024 * 1024;

    for (int data_bytes = MIN_BYTES; data_bytes <= MAX_BYTES; data_bytes *= 2) {
        std::vector<char> send_data(data_bytes, 1);
        std::vector<char> recv_data_allgather(static_cast<size_t>(data_bytes) * static_cast<size_t>(size), 0);

        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_manual = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            if (rank == 0) {
                for (int target = 1; target < size; target++) {
                    MPI_Send(send_data.data(), data_bytes, MPI_BYTE, target, 0, MPI_COMM_WORLD);
                }
            } else {
                MPI_Recv(send_data.data(), data_bytes, MPI_BYTE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
        }
        double t_end_manual = MPI_Wtime();

        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_bcast = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            MPI_Bcast(send_data.data(), data_bytes, MPI_BYTE, 0, MPI_COMM_WORLD);
        }
        double t_end_bcast = MPI_Wtime();

        MPI_Barrier(MPI_COMM_WORLD);
        double t_start_allgather = MPI_Wtime();
        for (int i = 0; i < NUM_ITERATIONS; i++) {
            MPI_Allgather(send_data.data(), data_bytes, MPI_BYTE,
                          recv_data_allgather.data(), data_bytes, MPI_BYTE, MPI_COMM_WORLD);
        }
        double t_end_allgather = MPI_Wtime();

        double time_manual = (t_end_manual - t_start_manual) / NUM_ITERATIONS;
        double time_bcast = (t_end_bcast - t_start_bcast) / NUM_ITERATIONS;
        double time_allgather = (t_end_allgather - t_start_allgather) / NUM_ITERATION S;

        if (rank == 0) {
            printf("%d,Manual_Bcast,%d,%.9f\n", size, data_bytes, time_manual);
            printf("%d,MPI_Bcast,%d,%.9f\n", size, data_bytes, time_bcast);
            printf("%d,MPI_Allgather,%d,%.9f\n", size, data_bytes, time_allgather);
        }
    }

    MPI_Finalize();
    return 0;
}
```

==== mpi_collective.sh
<mpi_collective.shのコード>

```sh
#!/bin/bash
#SBATCH -J mpi_collective
#SBATCH -N 4 # 4台の計算ノード全てを要求
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-03]
#SBATCH -o out/mpi_collective_%j.out
#SBATCH --ntasks=64

module load openmpi

mkdir -p out

echo "Processes,Method,DataSize_Bytes,AvgTime_sec"

for process_count in 2 4 8 16 32 64; do
	mpirun -n "${process_count}" ./mpi_collective
done
```

=== 5.2 (e) のソースコード

==== mpi_congestion.cpp
<mpi_congestion.cppのコード>

```cpp
#include <iostream>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // 全プロセスを (偶数rank, 偶数rank+1) でペアにするため偶数プロセス数を要求
    if (size < 2 || size % 2 != 0) {
        if (rank == 0) std::cerr << "Error: Requires an even number of processes (>= 2)." << std::endl;
        MPI_Finalize();
        return 1;
    }

    const int NUM_ITERATIONS = 20;
    const int MIN_BYTES = 8;
    const int MAX_BYTES = 16 * 1024 * 1024;

    const int half = size / 2;
    // 自分のペア相手（rank i <-> rank i + size/2）
    const int partner = (rank < half) ? rank + half : rank - half;

    for (int data_bytes = MIN_BYTES; data_bytes <= MAX_BYTES; data_bytes *= 2) {
        std::vector<char> data(data_bytes, 1);

        // ウォームアップ通信（1回のPing-Pong）でMPI内部の初期化ノイズを除去
        MPI_Barrier(MPI_COMM_WORLD);
        if (rank < half) {
            MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
            MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        } else {
            MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
        }

        // ダミー通信後に全員のタイミングを再同期してから本計測を開始
        MPI_Barrier(MPI_COMM_WORLD);
        double t_start = MPI_Wtime();

        for (int i = 0; i < NUM_ITERATIONS; i++) {
            if (rank < half) {
                MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
                MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            } else {
                MPI_Recv(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(data.data(), data_bytes, MPI_BYTE, partner, 0, MPI_COMM_WORLD);
            }
        }

        MPI_Barrier(MPI_COMM_WORLD);
        double t_end = MPI_Wtime();

        double elapsed_local = t_end - t_start;
        double elapsed_max = 0.0;
        MPI_Reduce(&elapsed_local, &elapsed_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

        if (rank == 0) {
            double avg_one_way_sec = elapsed_max / (2.0 * NUM_ITERATIONS);
            std::cout << size << "," << (size / 2) << "," << data_bytes << "," << avg_one_way_sec << "\n";
        }
    }

    MPI_Finalize();
    return 0;
}
```

==== mpi_congestion.sh
<mpi_congestion.shのコード>
```sh
#!/bin/bash
#SBATCH -J mpi_congestion
#SBATCH -N 4
#SBATCH -p ppx2
#SBATCH -w ppx2-[00-03]
#SBATCH -o out/mpi_congestion_%j.out
#SBATCH --ntasks=64

module load openmpi

mkdir -p out

echo "Processes,Pairs,DataSize_Bytes,AvgTime_sec"

for P in 2 4 8 16 32 64; do
	mpirun -n "$P" ./mpi_congestion
done
```