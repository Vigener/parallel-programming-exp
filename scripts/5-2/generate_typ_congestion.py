# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
import csv
import sys
from pathlib import Path


def format_size_label(size_bytes: int) -> str:
	"""Convert byte size to a human-friendly label."""
	if size_bytes >= 1_048_576 and size_bytes % 1_048_576 == 0:
		return f"{size_bytes // 1_048_576} MB"
	if size_bytes >= 1024 and size_bytes % 1024 == 0:
		return f"{size_bytes // 1024} KB"
	return f"{size_bytes} B"


def format_us_from_sec(value_sec: float) -> str:
	"""Format seconds as readable microseconds without scientific notation."""
	value_us = value_sec * 1_000_000.0
	abs_v = abs(value_us)

	# Keep 3-4 significant digits while avoiding exponent form.
	if abs_v >= 100:
		text = f"{value_us:.0f}"
	elif abs_v >= 10:
		text = f"{value_us:.1f}"
	elif abs_v >= 1:
		text = f"{value_us:.2f}"
	else:
		text = f"{value_us:.3f}"

	return text


def read_congestion_rows(csv_path: Path) -> dict[int, dict[int, float]]:
	"""Return mapping: data_size -> {processes: avg_time_sec}."""
	by_size: dict[int, dict[int, float]] = {}

	with csv_path.open("r", encoding="utf-8", newline="") as f:
		reader = csv.DictReader(f)
		required = {"Processes", "Pairs", "DataSize_Bytes", "AvgTime_sec"}
		if reader.fieldnames is None or not required.issubset(set(reader.fieldnames)):
			raise ValueError("CSVヘッダーが要件と一致しません。")

		for row in reader:
			proc = int(float(row["Processes"]))
			if proc not in {2, 16, 32, 64}:
				continue

			size = int(float(row["DataSize_Bytes"]))
			avg_time_sec = float(row["AvgTime_sec"])
			by_size.setdefault(size, {})[proc] = avg_time_sec

	return by_size


def build_typst_table(by_size: dict[int, dict[int, float]]) -> str:
	lines = [
		"#table(",
		"  columns: 5,",
		"  align: (auto, right, right, right, right),",
		"  table.header([データサイズ], [1ペア単独 (μs)], [8ペア同時 (μs)], [16ペア同時 (μs)], [32ペア同時 (μs)]),",
		"  table.hline(),",
	]

	for size in sorted(by_size.keys()):
		entry = by_size[size]
		if any(proc not in entry for proc in (2, 16, 32, 64)):
			# Compare only sizes where both conditions are available.
			continue

		size_label = format_size_label(size)
		single_pair = format_us_from_sec(entry[2])
		mid_pairs_8 = format_us_from_sec(entry[16])
		mid_pairs_16 = format_us_from_sec(entry[32])
		max_pairs = format_us_from_sec(entry[64])
		lines.append(f"  [{size_label}], [${single_pair}$], [${mid_pairs_8}$], [${mid_pairs_16}$], [${max_pairs}$],")

	lines.append(")")
	return "\n".join(lines) + "\n"


def main() -> None:
	if len(sys.argv) != 3:
		print("Usage: uv run scripts/5-2/generate_typ_congestion.py <input_csv_path> <output_typ_path>")
		sys.exit(1)

	input_csv = Path(sys.argv[1])
	output_typ = Path(sys.argv[2])

	rows_by_size = read_congestion_rows(input_csv)
	typst_table = build_typst_table(rows_by_size)

	output_typ.parent.mkdir(parents=True, exist_ok=True)
	output_typ.write_text(typst_table, encoding="utf-8")

	print(f"Typstファイルを保存しました: {output_typ}")


if __name__ == "__main__":
	main()

