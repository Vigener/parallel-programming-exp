# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
import argparse
import csv
from pathlib import Path


def read_series(csv_path: Path) -> list[tuple[int, float]]:
	series: list[tuple[int, float]] = []
	with csv_path.open("r", encoding="utf-8", newline="") as f:
		reader = csv.DictReader(f)
		for row in reader:
			size_bytes = int(float(row["DataSize_Bytes"]))
			time_sec = float(row["Time_sec"])
			series.append((size_bytes, time_sec))

	series.sort(key=lambda x: x[0])
	return series


def estimate_latency_us(
	series: list[tuple[int, float]],
	small_min_bytes: int,
	small_max_bytes: int,
	small_points: int,
) -> float:
	small_region = [
		time_sec
		for size_bytes, time_sec in series
		if small_min_bytes <= size_bytes <= small_max_bytes
	][:small_points]

	if not small_region:
		raise ValueError("小サイズ領域のデータが見つかりませんでした。")

	latency_sec = sum(small_region) / len(small_region)
	return latency_sec * 1_000_000


def estimate_bandwidth_gbps(series: list[tuple[int, float]], large_min_bytes: int) -> float:
	large_region = [(n, t) for n, t in series if n >= large_min_bytes and t > 0]
	if not large_region:
		raise ValueError("大サイズ領域のデータが見つかりませんでした。")

	bandwidth_bytes_per_sec = [n / t for n, t in large_region]
	avg_bytes_per_sec = sum(bandwidth_bytes_per_sec) / len(bandwidth_bytes_per_sec)
	return avg_bytes_per_sec / 1_000_000_000


def report(label: str, series: list[tuple[int, float]], args: argparse.Namespace) -> None:
	a_us = estimate_latency_us(
		series,
		small_min_bytes=args.small_min,
		small_max_bytes=args.small_max,
		small_points=args.small_points,
	)
	b_gbps = estimate_bandwidth_gbps(series, large_min_bytes=args.large_min)

	print(f"[{label}]")
	print(f"- Latency (a) : {a_us:.3f} µs")
	print(f"- Bandwidth (b): {b_gbps:.3f} GB/s")


def main() -> None:
	parser = argparse.ArgumentParser(
		description="MPI ping-pong CSVから T = a + (N / b) のa,bを推定します。"
	)
	parser.add_argument(
		"crossnode_csv",
		type=Path,
		nargs="?",
		default=Path("mpi_pingpong_crossnode.csv"),
		help="ノード間通信CSV",
	)
	parser.add_argument(
		"local_csv",
		type=Path,
		nargs="?",
		default=Path("mpi_pingpong_local.csv"),
		help="ノード内通信CSV",
	)
	parser.add_argument("--small-min", type=int, default=8, help="小サイズ領域の下限[Bytes]")
	parser.add_argument("--small-max", type=int, default=32, help="小サイズ領域の上限[Bytes]")
	parser.add_argument("--small-points", type=int, default=3, help="小サイズ領域で使う先頭点数")
	parser.add_argument(
		"--large-min",
		type=int,
		default=1_048_576,
		help="大サイズ領域の下限[Bytes] (例: 1MB)",
	)
	args = parser.parse_args()

	cross_series = read_series(args.crossnode_csv)
	local_series = read_series(args.local_csv)

	report("Cross Node", cross_series, args)
	report("Local Node", local_series, args)


if __name__ == "__main__":
	main()