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


def read_series(csv_path: Path) -> tuple[list[int], list[float]]:
	sizes: list[int] = []
	times_us: list[float] = []

	with csv_path.open("r", encoding="utf-8", newline="") as f:
		reader = csv.DictReader(f)
		for row in reader:
			size = int(float(row["DataSize_Bytes"]))
			time_us = float(row["Time_sec"]) * 1_000_000
			sizes.append(size)
			times_us.append(time_us)

	paired = sorted(zip(sizes, times_us), key=lambda x: x[0])
	sorted_sizes = [p[0] for p in paired]
	sorted_times_us = [p[1] for p in paired]
	return sorted_sizes, sorted_times_us


def main() -> None:
	parser = argparse.ArgumentParser(
		description="2つのMPI ping-pong CSVを重ねたlog-log折れ線グラフを作成します。"
	)
	parser.add_argument("local_csv", type=Path, help="ノード内通信CSV")
	parser.add_argument("crossnode_csv", type=Path, help="ノード間通信CSV")
	parser.add_argument(
		"--output",
		type=Path,
		default=Path("mpi_pingpong_comparison_loglog.png"),
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
	plt.yscale("log")

	plt.xlabel("データサイズ (Bytes)")
	plt.ylabel(r"通信時間 [$\mu$s]")
	plt.title("MPI Ping-Pong 通信時間比較（log-log）")

	plt.grid(True, which="major", linestyle="--", linewidth=0.8, alpha=0.6)
	plt.grid(True, which="minor", linestyle=":", linewidth=0.6, alpha=0.5)
	plt.legend()
	plt.tight_layout()

	output_path = args.output
	if not output_path.is_absolute():
		output_path = Path(__file__).parent / output_path
	plt.savefig(output_path, dpi=300, bbox_inches="tight")
	plt.close()

	print(f"PNGを保存しました: {output_path}")


if __name__ == "__main__":
	main()
