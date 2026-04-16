# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
import argparse
import csv
from pathlib import Path


METHODS = ["Manual_Bcast", "MPI_Bcast", "MPI_Allgather"]


def read_rows(csv_path: Path) -> list[dict[str, str]]:
	with csv_path.open("r", encoding="utf-8", newline="") as f:
		return list(csv.DictReader(f))


def format_grouped_decimal(value: float, decimals: int) -> str:
	"""Format number without scientific notation and trim decimal zeros."""
	text = f"{value:.{decimals}f}"
	if decimals > 0 and "." in text:
		text = text.rstrip("0").rstrip(".")
	return text


def fmt_us_from_sec(value_sec: float) -> str:
	"""Format seconds as plain decimal microseconds in Typst math."""
	value_us = value_sec * 1_000_000
	if value_us == 0:
		return "$0$"

	abs_v = abs(value_us)
	if abs_v >= 1000:
		text = format_grouped_decimal(value_us, 0)
	elif abs_v >= 100:
		text = format_grouped_decimal(value_us, 1)
	elif abs_v >= 10:
		text = format_grouped_decimal(value_us, 1)
	elif abs_v >= 1:
		text = format_grouped_decimal(value_us, 2)
	else:
		text = format_grouped_decimal(value_us, 3)
	return f"${text}$"


def format_size_label(size_bytes: int) -> str:
	"""Format byte size using B/KB/MB units."""
	if size_bytes >= 1_048_576 and size_bytes % 1_048_576 == 0:
		return f"{size_bytes // 1_048_576} MB"
	if size_bytes >= 1024 and size_bytes % 1024 == 0:
		return f"{size_bytes // 1024} KB"
	return f"{size_bytes} B"


def read_pingpong_data(csv_path: Path) -> dict[int, float]:
	"""Read ping-pong CSV and return mapping of DataSize_Bytes to Time_sec."""
	data = {}
	with csv_path.open("r", encoding="utf-8", newline="") as f:
		reader = csv.DictReader(f)
		for row in reader:
			size = int(float(row["DataSize_Bytes"]))
			time_sec = float(row["Time_sec"])
			data[size] = time_sec
	return data


def build_table1_p16(rows: list[dict[str, str]], pingpong_data: dict[int, float]) -> str:
	# Key: data size, Value: per-method time in seconds
	by_size: dict[int, dict[str, float]] = {}

	for row in rows:
		if int(row["Processes"]) != 16:
			continue
		size = int(row["DataSize_Bytes"])
		method = row["Method"]
		time_sec = float(row["AvgTime_sec"])
		if method not in METHODS:
			continue
		by_size.setdefault(size, {})[method] = time_sec

	lines = [
		"#figure(",
		"  align(center)[#table(",
		"    columns: 5,",
		"    align: (auto, auto, auto, auto, auto),",
		"    table.header([データサイズ (Bytes)], [Ping-Pong(ノード間) (μs)], [Manual_Bcast (μs)], [MPI_Bcast (μs)], [MPI_Allgather (μs)]),",
		"    table.hline(),",
	]

	# Merge sizes from both collective (P=16) and ping-pong data
	all_sizes = sorted(set(by_size.keys()) | set(pingpong_data.keys()))
	for size in all_sizes:
		entry = by_size.get(size, {})
		pingpong = pingpong_data.get(size)
		size_label = format_size_label(size)
		pingpong_str = fmt_us_from_sec(pingpong) if pingpong is not None else "-"
		manual = fmt_us_from_sec(entry.get("Manual_Bcast", 0.0)) if "Manual_Bcast" in entry else "-"
		mpi_bcast = fmt_us_from_sec(entry.get("MPI_Bcast", 0.0)) if "MPI_Bcast" in entry else "-"
		mpi_allgather = fmt_us_from_sec(entry.get("MPI_Allgather", 0.0)) if "MPI_Allgather" in entry else "-"
		lines.append(f"    [{size_label}], [{pingpong_str}], [{manual}], [{mpi_bcast}], [{mpi_allgather}],")

	lines.extend([
		"  )],",
		"  caption: [データサイズによる通信時間の比較（P=16 固定）],",
		"  kind: table",
		")",
	])
	return "\n".join(lines)


def build_table2_n8bytes(rows: list[dict[str, str]]) -> str:
	# Key: processes, Value: per-method time in seconds
	by_proc: dict[int, dict[str, float]] = {}

	for row in rows:
		if int(row["DataSize_Bytes"]) != 8:
			continue
		proc = int(row["Processes"])
		method = row["Method"]
		time_sec = float(row["AvgTime_sec"])
		if method not in METHODS:
			continue
		by_proc.setdefault(proc, {})[method] = time_sec

	lines = [
		"#figure(",
		"  align(center)[#table(",
		"    columns: 4,",
		"    align: (auto, auto, auto, auto),",
		"    table.header([プロセス数], [Manual_Bcast (μs)], [MPI_Bcast (μs)], [MPI_Allgather (μs)]),",
		"    table.hline(),",
	]

	for proc in sorted(by_proc.keys()):
		entry = by_proc[proc]
		manual = fmt_us_from_sec(entry.get("Manual_Bcast", 0.0)) if "Manual_Bcast" in entry else "-"
		mpi_bcast = fmt_us_from_sec(entry.get("MPI_Bcast", 0.0)) if "MPI_Bcast" in entry else "-"
		mpi_allgather = fmt_us_from_sec(entry.get("MPI_Allgather", 0.0)) if "MPI_Allgather" in entry else "-"
		lines.append(f"    [{proc}], [{manual}], [{mpi_bcast}], [{mpi_allgather}],")

	lines.extend([
		"  )],",
		"  caption: [プロセス数による通信時間の比較（N=8 Bytes 固定）],",
		"  kind: table",
		")",
	])
	return "\n".join(lines)


def build_table3_n1mb(rows: list[dict[str, str]]) -> str:
	# Key: processes, Value: per-method time in seconds
	by_proc: dict[int, dict[str, float]] = {}

	for row in rows:
		if int(row["DataSize_Bytes"]) != 1_048_576:
			continue
		proc = int(row["Processes"])
		method = row["Method"]
		time_sec = float(row["AvgTime_sec"])
		if method not in METHODS:
			continue
		by_proc.setdefault(proc, {})[method] = time_sec

	lines = [
		"#figure(",
		"  align(center)[#table(",
		"    columns: 4,",
		"    align: (auto, auto, auto, auto),",
		"    table.header([プロセス数], [Manual_Bcast (μs)], [MPI_Bcast (μs)], [MPI_Allgather (μs)]),",
		"    table.hline(),",
	]

	for proc in sorted(by_proc.keys()):
		entry = by_proc[proc]
		manual = fmt_us_from_sec(entry.get("Manual_Bcast", 0.0)) if "Manual_Bcast" in entry else "-"
		mpi_bcast = fmt_us_from_sec(entry.get("MPI_Bcast", 0.0)) if "MPI_Bcast" in entry else "-"
		mpi_allgather = fmt_us_from_sec(entry.get("MPI_Allgather", 0.0)) if "MPI_Allgather" in entry else "-"
		lines.append(f"    [{proc}], [{manual}], [{mpi_bcast}], [{mpi_allgather}],")

	lines.extend([
		"  )],",
		"  caption: [プロセス数による通信時間の比較（N=1MB 固定）],",
		"  kind: table",
		")",
	])
	return "\n".join(lines)


def main() -> None:
	parser = argparse.ArgumentParser(
		description="MPI集団通信CSVからTypst表（3表）を生成します。"
	)
	parser.add_argument("csv_path", type=Path, help="集団通信CSV")
	parser.add_argument("pingpong_csv", type=Path, help="Ping-Pong (Cross Node) CSV")
	parser.add_argument(
		"--output",
		type=Path,
		default=Path("mpi_collective_tables.typ"),
		help="出力Typstファイル名",
	)
	args = parser.parse_args()

	rows = read_rows(args.csv_path)
	if not rows:
		print("集団通信データが見つかりません。")
		return

	pingpong_data = read_pingpong_data(args.pingpong_csv)
	table1 = build_table1_p16(rows, pingpong_data)
	table2 = build_table2_n8bytes(rows)
	table3 = build_table3_n1mb(rows)
	content = f"{table1}\n\n{table2}\n\n{table3}\n"

	output_path = args.output
	if not output_path.is_absolute():
		output_path = Path(__file__).parent / output_path
	output_path.write_text(content, encoding="utf-8")

	print(f"Typstファイルを保存しました: {output_path}")


if __name__ == "__main__":
	main()
