# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pandas>=2.1.0",
#     "matplotlib>=3.10.8",
#     "japanize-matplotlib>=1.1.3",
#     "setuptools>=82.0.1",
# ]
# ///
import argparse
import sys
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import japanize_matplotlib
from matplotlib.backends.backend_pdf import PdfPages


FONT_SIZE_TITLE = 24
FONT_SIZE_AXIS_LABEL = 20
FONT_SIZE_TICKS = 14
FONT_SIZE_LEGEND = 14


def _select_series(df, per_node_mpi, omp_threads):
	# 条件: OpenMPスレッド数が合致し、MPI_Processes / Nodes が per_node_mpi
	mask = (df['OpenMP_Threads'] == omp_threads) & (df['MPI_Processes'] / df['Nodes'] == per_node_mpi)
	return df[mask].copy()


def plot_time(ax, series_dict, nodes_sorted, num_particles):
	for label, (df_s, color, marker) in series_dict.items():
		data = df_s.set_index('Nodes').reindex(nodes_sorted)
		ax.plot(nodes_sorted, data['Time_sec'], marker=marker, color=color, linewidth=2, markersize=8, label=label)
	ax.set_xlabel('ノード数', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_ylabel('実行時間 $T$ [s]', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_title(f'実行時間のスケーラビリティ (N={num_particles})', fontsize=FONT_SIZE_TITLE)
	ax.set_xticks(nodes_sorted)
	ax.tick_params(axis='x', labelsize=FONT_SIZE_TICKS)
	ax.tick_params(axis='y', labelsize=FONT_SIZE_TICKS)
	ax.legend(fontsize=FONT_SIZE_LEGEND)
	ax.grid(True, ls='--', alpha=0.6)


def plot_speedup(ax, series_dict, nodes_sorted, num_particles):
	for label, (df_s, color, marker) in series_dict.items():
		data = df_s.set_index('Nodes').reindex(nodes_sorted)
		t1 = data.loc[1, 'Time_sec'] if 1 in data.index and pd.notna(data.loc[1, 'Time_sec']) else None
		if t1 is None:
			continue
		speedup = t1 / data['Time_sec']
		ax.plot(nodes_sorted, speedup, marker=marker, color=color, linewidth=2, markersize=8, label=label)
	# 理想線 y = x
	ax.plot(nodes_sorted, nodes_sorted, linestyle='--', color='k', linewidth=1.5, label='理想 (y=x)')
	ax.set_xlabel('ノード数', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_ylabel('速度向上率 $S(p)$', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_title(f'速度向上率 (Speedup) (N={num_particles})', fontsize=FONT_SIZE_TITLE)
	ax.set_xticks(nodes_sorted)
	ax.tick_params(axis='x', labelsize=FONT_SIZE_TICKS)
	ax.tick_params(axis='y', labelsize=FONT_SIZE_TICKS)
	ax.legend(fontsize=FONT_SIZE_LEGEND)
	ax.grid(True, ls='--', alpha=0.6)


def plot_efficiency(ax, series_dict, nodes_sorted, num_particles):
	for label, (df_s, color, marker) in series_dict.items():
		data = df_s.set_index('Nodes').reindex(nodes_sorted)
		t1 = data.loc[1, 'Time_sec'] if 1 in data.index and pd.notna(data.loc[1, 'Time_sec']) else None
		if t1 is None:
			continue
		speedup = t1 / data['Time_sec']
		efficiency = speedup / pd.Series(nodes_sorted, index=nodes_sorted)
		ax.plot(nodes_sorted, efficiency, marker=marker, color=color, linewidth=2, markersize=8, label=label)
	ax.set_xlabel('ノード数', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_ylabel('並列化効率 $E(p)$', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_title(f'並列化効率 (Efficiency) (N={num_particles})', fontsize=FONT_SIZE_TITLE)
	ax.set_xticks(nodes_sorted)
	ax.set_ylim(0, 1.05)
	ax.tick_params(axis='x', labelsize=FONT_SIZE_TICKS)
	ax.tick_params(axis='y', labelsize=FONT_SIZE_TICKS)
	ax.legend(fontsize=FONT_SIZE_LEGEND)
	ax.grid(True, ls='--', alpha=0.6)


def plot_performance_by_size(ax, df_all, nodes_target=4):
	"""
	グラフ①: 問題サイズごとの性能限界（N vs GIPS）
	- 横軸: データサイズ N（Logスケール）
	- 縦軸: 計算性能 GIPS [G interactions/s]
	- ノード数4のデータのみを対象
	"""
	colors = {'28MPIプロセス×1OpenMPスレッド': '#d62728', '4MPIプロセス×7OpenMPスレッド': '#2ca02c', '1MPIプロセス×28OpenMPスレッド': '#1f77b4'}
	markers = {'28MPIプロセス×1OpenMPスレッド': 'o', '4MPIプロセス×7OpenMPスレッド': 's', '1MPIプロセス×28OpenMPスレッド': '^'}
	
	# ノード数を絞る
	df_filtered = df_all[df_all['Nodes'] == nodes_target].copy()
	
	# 異なるN値を取得
	unique_n = sorted(df_filtered['NumParticles'].unique())
	
	# 各手法ごとにプロット
	configs = [
		(28, 1, '28MPIプロセス×1OpenMPスレッド'),
		(4, 7, '4MPIプロセス×7OpenMPスレッド'),
		(1, 28, '1MPIプロセス×28OpenMPスレッド'),
	]
	
	for per_node_mpi, omp_threads, label in configs:
		series = _select_series(df_filtered, per_node_mpi, omp_threads)
		if series.empty:
			continue
		
		# GIPS を計算
		series_sorted = series.sort_values('NumParticles')
		gips_values = (series_sorted['NumParticles'] * (series_sorted['NumParticles'] - 1) * 1000) / (series_sorted['Time_sec'] * 1e9)
		n_values = series_sorted['NumParticles'].values
		
		ax.loglog(n_values, gips_values, marker=markers[label], color=colors[label], linewidth=2, markersize=8, label=label)
	
	ax.set_xlabel('問題サイズ $N$ (粒子数)', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_ylabel('計算性能 GIPS [G interactions/s]', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_title(f'問題サイズごとの性能限界 (Nodes={nodes_target})', fontsize=FONT_SIZE_TITLE)
	ax.tick_params(axis='x', labelsize=FONT_SIZE_TICKS)
	ax.tick_params(axis='y', labelsize=FONT_SIZE_TICKS)
	ax.legend(fontsize=FONT_SIZE_LEGEND)
	ax.grid(True, which='both', ls='--', alpha=0.6)


def plot_speedup_by_size(ax, df_all):
	"""
	グラフ②: 強いスケーリング（Nodes vs Speedup）の「Nによる違い」
	- 横軸: ノード数（1, 2, 4）
	- 縦軸: 速度向上率 S(p)
	- Pure Hybrid のみ、N=896 と N=26880 の2本
	"""
	# Nのリスト（小->大）を全て表示する
	n_list = [896, 2688, 8960, 26880]
	markers = ['o', 's', '^', 'D']

	# カラーマップで連続的な色を生成（小さいNが薄く、大きいNが濃く見える）
	# 暖色系で明るめのパレットに変更（plasma: 明るくコントラストが出る）
	cmap = plt.cm.autumn
	colors = [cmap(i / (len(n_list) - 1)) for i in range(len(n_list))]

	# Pure Hybrid のデータを抽出
	pure_hybrid_all = _select_series(df_all, per_node_mpi=1, omp_threads=28)

	for idx, n_value in enumerate(n_list):
		series = pure_hybrid_all[pure_hybrid_all['NumParticles'] == n_value].copy()
		if series.empty:
			continue

		series_sorted = series.sort_values('Nodes')
		nodes_list = sorted(series_sorted['Nodes'].unique())

		t1 = series_sorted[series_sorted['Nodes'] == 1]['Time_sec'].values
		if len(t1) == 0:
			continue
		t1 = t1[0]

		speedup_values = []
		for node in nodes_list:
			t_node = series_sorted[series_sorted['Nodes'] == node]['Time_sec'].values
			if len(t_node) > 0:
				speedup_values.append(t1 / t_node[0])

		label = f'1MPIプロセス×28OpenMPスレッド (N={n_value})'
		ax.plot(nodes_list, speedup_values, marker=markers[idx % len(markers)], color=colors[idx], linewidth=2, markersize=8, label=label)
	
	# 理想線
	nodes_ideal = [1, 2, 4]
	ax.plot(nodes_ideal, nodes_ideal, linestyle='--', color='k', linewidth=1.5, label='理想 (y=x)')
	
	ax.set_xlabel('ノード数', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_ylabel('速度向上率 $S(p)$', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_title('強いスケーリング (1MPI×28openMP)', fontsize=FONT_SIZE_TITLE)
	ax.set_xticks(nodes_ideal)
	ax.tick_params(axis='x', labelsize=FONT_SIZE_TICKS)
	ax.tick_params(axis='y', labelsize=FONT_SIZE_TICKS)
	ax.legend(fontsize=FONT_SIZE_LEGEND)
	ax.grid(True, ls='--', alpha=0.6)


def plot_gustafson(ax, df_all):
	"""
	問題サイズ N による並列化効率の比較（Gustafson の法則を示すグラフ）
	- 対象: Pure Hybrid (1MPIプロセス × 28OpenMPスレッド)
	- 横軸: ノード数 [1,2,4]
	- 縦軸: 並列化効率 E(p)（0.0 ～ 1.1）
	- 系列: N = 896, 2688, 8960, 26880
	"""
	n_list = [896, 2688, 8960, 26880]
	markers = ['o', 's', '^', 'D']
	colors = {896: '#1f77b4', 2688: '#2ca02c', 8960: '#ff7f0e', 26880: '#d62728'}

	pure_hybrid_all = _select_series(df_all, per_node_mpi=1, omp_threads=28)
	nodes_plot = [1, 2, 4]

	for idx, n_value in enumerate(n_list):
		series = pure_hybrid_all[pure_hybrid_all['NumParticles'] == n_value].copy()
		if series.empty:
			continue

		series_sorted = series.sort_values('Nodes')

		# 基準となる1ノードの時間
		t1_arr = series_sorted[series_sorted['Nodes'] == 1]['Time_sec'].values
		if len(t1_arr) == 0:
			continue
		t1 = t1_arr[0]

		eff_values = []
		for p in nodes_plot:
			t_arr = series_sorted[series_sorted['Nodes'] == p]['Time_sec'].values
			if len(t_arr) == 0 or pd.isna(t_arr[0]) or t_arr[0] == 0:
				eff_values.append(float('nan'))
			else:
				speedup = t1 / t_arr[0]
				efficiency = speedup / p
				eff_values.append(efficiency)

		label = f'1MPIプロセス×28OpenMPスレッド (N={n_value})'
		ax.plot(nodes_plot, eff_values, marker=markers[idx % len(markers)], color=colors[n_value], linewidth=2, markersize=8, label=label)

	ax.plot(nodes_plot, nodes_plot, linestyle='')  # noop to ensure integer x-axis scale
	ax.set_xlabel('ノード数', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_ylabel('並列化効率 $E(p)$', fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_title('問題サイズによる並列化効率 (1MPI×28thread)', fontsize=FONT_SIZE_TITLE)
	ax.set_xticks(nodes_plot)
	ax.set_ylim(0.0, 1.1)
	ax.tick_params(axis='x', labelsize=FONT_SIZE_TICKS)
	ax.tick_params(axis='y', labelsize=FONT_SIZE_TICKS)
	ax.legend(fontsize=FONT_SIZE_LEGEND)
	ax.grid(True, ls='--', alpha=0.6)


def main():
	parser = argparse.ArgumentParser(description='nbody hybrid の実験結果から5つのグラフを作成します')
	parser.add_argument('input_csv', help='入力CSVファイル (例: data/nbody_hybrid.csv)')
	parser.add_argument('output_pdf', help='出力PDFファイル (例: assets/5-4/nbody_hybrid.pdf)')
	parser.add_argument('--num-particles', type=int, default=None, help='プロット対象の NumParticles を指定（未指定で最小値を使用）')
	args = parser.parse_args()

	input_path = Path(args.input_csv)
	output_path = Path(args.output_pdf)

	if not input_path.exists():
		print(f"Error: input CSV not found: {input_path}")
		sys.exit(1)

	df_all = pd.read_csv(input_path)

	# NumParticles の選択（グラフ1-3 用）
	unique_particles = sorted(df_all['NumParticles'].dropna().unique())
	if args.num_particles is None:
		num_particles = int(unique_particles[0])
	else:
		num_particles = int(args.num_particles)
	df = df_all[df_all['NumParticles'] == num_particles].copy()

	if df.empty:
		print(f"指定した NumParticles={num_particles} のデータが見つかりません")
		sys.exit(1)

	# シリーズ定義 (label: (df_filtered, color, marker))
	flat = _select_series(df, per_node_mpi=28, omp_threads=1)
	hybrid = _select_series(df, per_node_mpi=4, omp_threads=7)
	pure_hybrid = _select_series(df, per_node_mpi=1, omp_threads=28)

	colors = {'Flat MPI': '#d62728', 'Hybrid': '#2ca02c', 'Pure Hybrid': '#1f77b4'}
	markers = {'Flat MPI': 'o', 'Hybrid': 's', 'Pure Hybrid': '^'}

	series_dict = {}
	if not flat.empty:
		series_dict['28MPIプロセス×1OpenMPスレッド'] = (flat, colors['Flat MPI'], markers['Flat MPI'])
	if not hybrid.empty:
		series_dict['4MPIプロセス×7OpenMPスレッド'] = (hybrid, colors['Hybrid'], markers['Hybrid'])
	if not pure_hybrid.empty:
		series_dict['1MPIプロセス×28OpenMPスレッド'] = (pure_hybrid, colors['Pure Hybrid'], markers['Pure Hybrid'])

	if not series_dict:
		print('対象となる系列データがありません。CSVの列を確認してください。')
		sys.exit(1)

	# ノードのソート順
	nodes_sorted = sorted(df['Nodes'].dropna().unique())

	# PDF に5ページで出力
	output_path.parent.mkdir(parents=True, exist_ok=True)
	with PdfPages(output_path) as pdf:
		# 1: Time
		fig, ax = plt.subplots(figsize=(8, 6))
		plot_time(ax, series_dict, nodes_sorted, num_particles)
		pdf.savefig(fig, bbox_inches='tight')
		plt.close(fig)

		# 2: Speedup
		fig, ax = plt.subplots(figsize=(8, 6))
		plot_speedup(ax, series_dict, nodes_sorted, num_particles)
		pdf.savefig(fig, bbox_inches='tight')
		plt.close(fig)

		# 3: Efficiency
		fig, ax = plt.subplots(figsize=(8, 6))
		plot_efficiency(ax, series_dict, nodes_sorted, num_particles)
		pdf.savefig(fig, bbox_inches='tight')
		plt.close(fig)

		# 4: Performance by Size (N vs GIPS)
		fig, ax = plt.subplots(figsize=(8, 6))
		plot_performance_by_size(ax, df_all, nodes_target=4)
		pdf.savefig(fig, bbox_inches='tight')
		plt.close(fig)

		# 5: Speedup by Size (Pure Hybrid with N=896 and N=26880)
		fig, ax = plt.subplots(figsize=(8, 6))
		plot_speedup_by_size(ax, df_all)
		pdf.savefig(fig, bbox_inches='tight')
		plt.close(fig)

		# 6: Gustafson / Amdahl-break (Efficiency vs Nodes for multiple N)
		fig, ax = plt.subplots(figsize=(8, 6))
		plot_gustafson(ax, df_all)
		pdf.savefig(fig, bbox_inches='tight')
		plt.close(fig)

	print(f"Saved 6 plots to {output_path} (NumParticles={num_particles})")


if __name__ == '__main__':
	main()

# ① 実行時間のスケーラビリティ（Time vs Nodes）
# - 横軸 (X): ノード数（1, 2, 4）※LinearでもLogでも可
# - 縦軸 (Y): 実行時間 $T$ [s]（Linear）
# - 見せたいこと: ノードを増やすと純粋に時間が短くなる様子。
# ② 速度向上率（Speedup）
# - 横軸 (X): ノード数（1, 2, 4）縦軸 (Y): 速度向上率 $S(p) = T(1ノード) / T(pノード)$
# - 見せたいこと: ノード数を2倍、4倍にしたとき、速度も2倍、4倍に近づくか。
# - グラフ上に必ず 「理想線（Ideal: $y = x$）」 の点線を引いてください。実データが理想線からどれだけ剥がれ落ちていくかを見せるのがHPC論文の鉄則です。
# ③ 並列化効率（Efficiency）
# - 横軸 (X): ノード数（1, 2, 4）
# - 縦軸 (Y): 並列化効率 $E(p) = S(p) / p$ （範囲は 0.0 〜 1.0）
# - 見せたいこと: 1.0（100%）からスタートし、ノードが増えて通信の渋滞（アムダールの法則）が顕在化するにつれて、グラフが右肩下がりに落ちていく残酷な現実。特に Flat MPI が最も激しく落ち込み、Pure Hybrid が 1.0 付近で耐え抜く様子が描ければ完璧です。

# 全パターンを載せるのではなく、以下の3つの系列（Legend）に絞ってグラフを描画してください。
# 1. Flat MPI: 1ノードあたり 28 MPIプロセス × 1 OMPスレッド (通信過多の最悪ケース)
# 2. Hybrid (中間): 1ノードあたり 4 MPIプロセス × 7 OMPスレッド (バランス型)
# 3. Pure Hybrid: 1ノードあたり 1 MPIプロセス × 28 OMPスレッド (理論上の最良ケース)

# 【完成イメージ】全部あわせて3枚の構成具体的には、以下のような「3枚のグラフ」を作成します。1枚目：実行時間のスケーラビリティ (Time)グラフの中身: 1つのグラフの中に、以下の3本の線が引かれます。🔴 Flat MPI の線🟢 Hybrid の線🔵 Pure Hybrid の線視覚効果: ノード数が増えるにつれて、どの線が一番下（時間が短い）にいくかで、最速の手法が一目でわかります。2枚目：速度向上率 (Speedup)グラフの中身: 1つのグラフの中に、以下の4本の線が引かれます。🔴 Flat MPI の線🟢 Hybrid の線🔵 Pure Hybrid の線⚪️ 理想線（$y = x$ の点線）視覚効果: ノード数を2, 4と増やしたとき、どの線が一番「理想の点線」に食らいついていけるか（どの線が早く脱落するか）が競争のように見えます。3枚目：並列化効率 (Efficiency)グラフの中身: 1つのグラフの中に、以下の3本の線が引かれます。🔴 Flat MPI の線🟢 Hybrid の線🔵 Pure Hybrid の線視覚効果: 左端の 1.0 (100%) からスタートし、ノードが増えるにつれてどの線が一番「急降下」するかで、通信渋滞の深刻さが比較できます。