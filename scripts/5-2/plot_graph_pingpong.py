# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "matplotlib>=3.10.8",
#     "japanize-matplotlib>=1.1.3",
#     "setuptools>=82.0.1",
# ]
# ///
import argparse
import csv
from pathlib import Path

import japanize_matplotlib
import matplotlib.pyplot as plt


FONT_SIZE_TITLE = 24
FONT_SIZE_AXIS_LABEL = 22
FONT_SIZE_TICKS = 14
FONT_SIZE_LEGEND = 18


def read_series(csv_path: Path) -> tuple[list[int], list[float]]:
	sizes: list[int] = []
	bandwidths_mb_s: list[float] = []

	with csv_path.open("r", encoding="utf-8", newline="") as f:
		reader = csv.DictReader(f)
		for row in reader:
			size = int(float(row["DataSize_Bytes"]))
			time_sec = float(row["Time_sec"])
			if time_sec <= 0:
				continue
			bandwidth_mb_s = (size / time_sec) / 1_000_000
			sizes.append(size)
			bandwidths_mb_s.append(bandwidth_mb_s)

	paired = sorted(zip(sizes, bandwidths_mb_s), key=lambda x: x[0])
	sorted_sizes = [p[0] for p in paired]
	sorted_bandwidths_mb_s = [p[1] for p in paired]
	return sorted_sizes, sorted_bandwidths_mb_s


def main() -> None:
	parser = argparse.ArgumentParser(
		description="2つのMPI ping-pong CSVを重ねたlog-linear折れ線グラフを作成します。"
	)
	parser.add_argument("local_csv", type=Path, help="ノード内通信CSV")
	parser.add_argument("crossnode_csv", type=Path, help="ノード間通信CSV")
	parser.add_argument(
		"--output",
		type=Path,
		default=Path("mpi_pingpong_comparison_loglinear_bandwidth_vs_size.png"),
		help="出力PNGファイル名",
	)
	args = parser.parse_args()

	local_x, local_y = read_series(args.local_csv)
	cross_x, cross_y = read_series(args.crossnode_csv)

	plt.figure(figsize=(9, 5.5))

	# 実測データの点をそのままマーカー付き折れ線で結ぶ（回帰直線は描かない）
	plt.plot(
		local_x,
		local_y,
		marker="o",
		markersize=5,
		linewidth=2,
		color="#1f77b4",
		label="ノード内通信",
	)
	plt.plot(
		cross_x,
		cross_y,
		marker="x",
		markersize=6,
		linewidth=2,
		color="#d62728",
		label="ノード間通信",
	)

	plt.xscale("log")
	plt.yscale("linear")

	plt.xlabel("データサイズ (Bytes)", fontsize=FONT_SIZE_AXIS_LABEL)
	plt.ylabel("バンド幅 [MB/s]", fontsize=FONT_SIZE_AXIS_LABEL)
	plt.title("MPI Ping-Pong 通信時間比較（log-log）", fontsize=FONT_SIZE_TITLE)
	plt.xticks(fontsize=FONT_SIZE_TICKS)
	plt.yticks(fontsize=FONT_SIZE_TICKS)

	plt.grid(True, which="major", linestyle="--", linewidth=0.8, alpha=0.6)
	plt.grid(True, which="minor", linestyle=":", linewidth=0.6, alpha=0.5)
	plt.legend(fontsize=FONT_SIZE_LEGEND)
	plt.tight_layout()

	output_path = args.output
	output_path.parent.mkdir(parents=True, exist_ok=True)
	plt.savefig(output_path, dpi=300, bbox_inches="tight")
	plt.close()

	print(f"PNGを保存しました: {output_path}")


if __name__ == "__main__":
	main()
