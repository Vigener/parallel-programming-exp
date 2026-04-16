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
import csv
from pathlib import Path

import japanize_matplotlib
import matplotlib.pyplot as plt
import pandas as pd


def read_pingpong_csv(csv_path: Path) -> tuple[list[int], list[float]]:
	"""Read ping-pong CSV and return (sizes, times_sec)."""
	sizes: list[int] = []
	times_sec: list[float] = []

	with csv_path.open("r", encoding="utf-8", newline="") as f:
		reader = csv.DictReader(f)
		for row in reader:
			size = int(float(row["DataSize_Bytes"]))
			time_sec = float(row["Time_sec"])
			sizes.append(size)
			times_sec.append(time_sec)

	paired = sorted(zip(sizes, times_sec), key=lambda x: x[0])
	sorted_sizes = [p[0] for p in paired]
	sorted_times_sec = [p[1] for p in paired]
	return sorted_sizes, sorted_times_sec


def make_figure1_size_vs_time(
	collective_csv: Path, pingpong_csv: Path, output_path: Path
) -> None:
	"""Create Figure 1: Data Size vs Communication Time (log-log)."""
	# Read data
	df_collective = pd.read_csv(collective_csv)
	pingpong_sizes, pingpong_times = read_pingpong_csv(pingpong_csv)

	# Filter collective data for P=16
	df_p16 = df_collective[df_collective["Processes"] == 16]

	# Extract series by method
	df_manual = df_p16[df_p16["Method"] == "Manual_Bcast"].sort_values("DataSize_Bytes")
	df_mpi_bcast = df_p16[df_p16["Method"] == "MPI_Bcast"].sort_values("DataSize_Bytes")
	df_mpi_allgather = df_p16[df_p16["Method"] == "MPI_Allgather"].sort_values("DataSize_Bytes")

	# Create figure
	plt.figure(figsize=(11, 7))

	# Plot ping-pong (cross node)
	plt.plot(
		pingpong_sizes,
		pingpong_times,
		marker="o",
		markersize=5,
		linewidth=2.0,
		color="#1f77b4",
		label="Ping-Pong (Cross Node)",
	)

	# Plot collective methods for P=16
	plt.plot(
		df_manual["DataSize_Bytes"],
		df_manual["AvgTime_sec"],
		marker="s",
		markersize=5,
		linewidth=2.0,
		color="#ff7f0e",
		label="P=16 Manual_Bcast",
	)

	plt.plot(
		df_mpi_bcast["DataSize_Bytes"],
		df_mpi_bcast["AvgTime_sec"],
		marker="^",
		markersize=5,
		linewidth=2.0,
		color="#2ca02c",
		label="P=16 MPI_Bcast",
	)

	plt.plot(
		df_mpi_allgather["DataSize_Bytes"],
		df_mpi_allgather["AvgTime_sec"],
		marker="D",
		markersize=5,
		linewidth=2.0,
		color="#d62728",
		label="P=16 MPI_Allgather",
	)

	# Formatting
	plt.xscale("log")
	plt.yscale("log")
	plt.xlabel("データサイズ (Bytes)", fontsize=12)
	plt.ylabel("通信時間 (sec)", fontsize=12)
	plt.title("MPI Ping-Pong vs 集団通信（P=16）の通信コスト比較", fontsize=13, fontweight="bold")

	plt.grid(True, which="both", linestyle="--", linewidth=0.7, alpha=0.6)
	plt.legend(fontsize=10, loc="upper left")
	plt.tight_layout()

	# Save figure
	output_path = Path(output_path)
	if not output_path.is_absolute():
		output_path = Path(__file__).parent / output_path
	plt.savefig(output_path, dpi=300, bbox_inches="tight")
	plt.close()

	print(f"Figure 1 saved: {output_path}")


def make_figure2_procs_vs_time(collective_csv: Path, output_path: Path) -> None:
	"""Create Figure 2: Number of Processes vs Communication Time (log-log)."""
	# Read data
	df = pd.read_csv(collective_csv)

	# Extract data for small (8 Bytes) and large (1 MB) sizes
	df_small = df[df["DataSize_Bytes"] == 8].sort_values("Processes")
	df_large = df[df["DataSize_Bytes"] == 1048576].sort_values("Processes")

	# Create figure
	plt.figure(figsize=(11, 7))

	# Plot for 8 Bytes (dashed lines)
	for method, color in [
		("Manual_Bcast", "#1f77b4"),
		("MPI_Bcast", "#ff7f0e"),
		("MPI_Allgather", "#2ca02c"),
	]:
		df_small_method = df_small[df_small["Method"] == method]
		plt.plot(
			df_small_method["Processes"],
			df_small_method["AvgTime_sec"],
			marker="o",
			markersize=6,
			linewidth=2.0,
			linestyle="--",
			color=color,
			label=f"8 Bytes - {method}",
		)

	# Plot for 1 MB (solid lines)
	for method, color in [
		("Manual_Bcast", "#1f77b4"),
		("MPI_Bcast", "#ff7f0e"),
		("MPI_Allgather", "#2ca02c"),
	]:
		df_large_method = df_large[df_large["Method"] == method]
		plt.plot(
			df_large_method["Processes"],
			df_large_method["AvgTime_sec"],
			marker="s",
			markersize=6,
			linewidth=2.0,
			linestyle="-",
			color=color,
			label=f"1 MB - {method}",
		)

	# Formatting
	plt.xscale("log")
	plt.yscale("log")

	# Set X-axis ticks to powers of 2
	proc_values = sorted(df["Processes"].unique())
	plt.xticks(proc_values, [str(p) for p in proc_values])

	plt.xlabel("プロセス数", fontsize=12)
	plt.ylabel("通信時間 (sec)", fontsize=12)
	plt.title("MPI 集団通信：プロセス数の増加による通信時間の変化", fontsize=13, fontweight="bold")

	plt.grid(True, which="both", linestyle="--", linewidth=0.7, alpha=0.6)
	plt.legend(fontsize=9, loc="upper left", ncol=2)
	plt.tight_layout()

	# Save figure
	output_path = Path(output_path)
	if not output_path.is_absolute():
		output_path = Path(__file__).parent / output_path
	plt.savefig(output_path, dpi=300, bbox_inches="tight")
	plt.close()

	print(f"Figure 2 saved: {output_path}")


def main() -> None:
	parser = argparse.ArgumentParser(
		description="MPI 集団通信ベンチマークの高品質グラフを作成します。"
	)
	parser.add_argument(
		"collective_csv",
		type=Path,
		nargs="?",
		default=Path("mpi_collective_112.csv"),
		help="集団通信ベンチマークCSV",
	)
	parser.add_argument(
		"--pingpong-csv",
		type=Path,
		default=Path("mpi_pingpong_crossnode.csv"),
		help="Ping-PongベンチマークCSV（クロスノード）",
	)
	parser.add_argument(
		"--output1",
		type=Path,
		default=Path("mpi_collective_size_vs_time.png"),
		help="Figure 1の出力PNGファイル名",
	)
	parser.add_argument(
		"--output2",
		type=Path,
		default=Path("mpi_collective_procs_vs_time.png"),
		help="Figure 2の出力PNGファイル名",
	)
	args = parser.parse_args()

	make_figure1_size_vs_time(args.collective_csv, args.pingpong_csv, args.output1)
	make_figure2_procs_vs_time(args.collective_csv, args.output2)


if __name__ == "__main__":
	main()
