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


PROJECT_ROOT = Path(__file__).resolve().parents[2]

FONT_SIZE_TITLE = 24
FONT_SIZE_AXIS_LABEL = 22
FONT_SIZE_TICKS = 14
FONT_SIZE_LEGEND = 18

def resolve_input_path(path: Path) -> Path:
	if path.is_absolute():
		return path
	return PROJECT_ROOT / path


def resolve_output_path(path: Path) -> Path:
	if path.is_absolute():
		resolved = path
	else:
		resolved = PROJECT_ROOT / path
	resolved.parent.mkdir(parents=True, exist_ok=True)
	return resolved


def read_collective_csv(csv_path: Path) -> pd.DataFrame:
	"""Read collective CSV and add bandwidth [MB/s] converted from AvgTime_sec."""
	df = pd.read_csv(csv_path)
	df = df[df["AvgTime_sec"] > 0].copy()
	df["Bandwidth_MBps"] = (df["DataSize_Bytes"] / df["AvgTime_sec"]) / 1_000_000
	return df


def read_pingpong_csv(csv_path: Path) -> tuple[list[int], list[float]]:
	"""Read ping-pong CSV and return (sizes, bandwidths_MBps)."""
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


def make_figure1_size_vs_time(
	collective_csv: Path, pingpong_csv: Path, output_path: Path
) -> None:
	"""Create Figure 1: Data Size vs Communication Bandwidth (log-log)."""
	# Read data
	df_collective = read_collective_csv(collective_csv)
	pingpong_sizes, pingpong_bandwidths = read_pingpong_csv(pingpong_csv)

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
		pingpong_bandwidths,
		marker="o",
		markersize=5,
		linewidth=2.0,
		color="#1f77b4",
		label="Ping-Pong (Cross Node)",
	)

	# Plot collective methods for P=16
	plt.plot(
		df_manual["DataSize_Bytes"],
		df_manual["Bandwidth_MBps"],
		marker="s",
		markersize=5,
		linewidth=2.0,
		color="#ff7f0e",
		label="P=16 Manual_Bcast",
	)

	plt.plot(
		df_mpi_bcast["DataSize_Bytes"],
		df_mpi_bcast["Bandwidth_MBps"],
		marker="^",
		markersize=5,
		linewidth=2.0,
		color="#2ca02c",
		label="P=16 MPI_Bcast",
	)

	plt.plot(
		df_mpi_allgather["DataSize_Bytes"],
		df_mpi_allgather["Bandwidth_MBps"],
		marker="D",
		markersize=5,
		linewidth=2.0,
		color="#d62728",
		label="P=16 MPI_Allgather",
	)

	# Formatting
	plt.xscale("log")
	plt.yscale("log")
	plt.xlabel("データサイズ (Bytes)", fontsize=FONT_SIZE_AXIS_LABEL)
	plt.ylabel("バンド幅 [MB/s]", fontsize=FONT_SIZE_AXIS_LABEL)
	plt.title(
		"MPI Ping-Pong vs 集団通信（P=16）の通信コスト比較",
		fontsize=FONT_SIZE_TITLE,
		fontweight="bold",
	)
	plt.xticks(fontsize=FONT_SIZE_TICKS)
	plt.yticks(fontsize=FONT_SIZE_TICKS)

	plt.grid(True, which="both", linestyle="--", linewidth=0.7, alpha=0.6)
	plt.legend(fontsize=FONT_SIZE_LEGEND, loc="upper left")
	plt.tight_layout()

	# Save figure
	output_path = resolve_output_path(Path(output_path))
	plt.savefig(output_path, dpi=300, bbox_inches="tight")
	plt.close()

	print(f"Figure 1 saved: {output_path}")


def make_figure2_procs_vs_time(collective_csv: Path, output_path: Path) -> None:
	"""Create Figure 2: Number of Processes vs Communication Time (log-log)."""
	# Read data
	df = read_collective_csv(collective_csv)

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
	plt.xticks(proc_values, [str(p) for p in proc_values], fontsize=FONT_SIZE_TICKS)

	plt.xlabel("プロセス数", fontsize=FONT_SIZE_AXIS_LABEL)
	plt.ylabel("通信時間 (sec)", fontsize=FONT_SIZE_AXIS_LABEL)
	plt.title(
		"MPI 集団通信：プロセス数の増加による通信時間の変化",
		fontsize=FONT_SIZE_TITLE,
		fontweight="bold",
	)
	plt.yticks(fontsize=FONT_SIZE_TICKS)

	plt.grid(True, which="both", linestyle="--", linewidth=0.7, alpha=0.6)
	plt.legend(fontsize=FONT_SIZE_LEGEND, loc="upper left", ncol=2)
	plt.tight_layout()

	# Save figure
	output_path = resolve_output_path(Path(output_path))
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
		default=Path("mpi_collective_size_vs_time.pdf"),
		help="Figure 1の出力PDFファイル名",
	)
	parser.add_argument(
		"--output2",
		type=Path,
		default=Path("mpi_collective_procs_vs_time.pdf"),
		help="Figure 2の出力PDFファイル名",
	)
	args = parser.parse_args()
	collective_csv = resolve_input_path(args.collective_csv)
	pingpong_csv = resolve_input_path(args.pingpong_csv)

	make_figure1_size_vs_time(collective_csv, pingpong_csv, args.output1)
	make_figure2_procs_vs_time(collective_csv, args.output2)


if __name__ == "__main__":
	main()
