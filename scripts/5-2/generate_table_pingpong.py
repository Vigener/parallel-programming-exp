# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
import argparse
import csv
from pathlib import Path


def read_rows(csv_path: Path) -> list[dict[str, str]]:
	with csv_path.open("r", encoding="utf-8", newline="") as f:
		return list(csv.DictReader(f))


def fmt_sig3(value: float) -> str:
	"""Format with 3 significant digits for human-friendly display."""
	if value == 0:
		return "0"
	return f"{value:.3g}"


def format_grouped_decimal(value: float, decimals: int) -> str:
	"""Format number without scientific notation and trim decimal zeros."""
	text = f"{value:.{decimals}f}"
	if decimals > 0 and "." in text:
		text = text.rstrip("0").rstrip(".")
	return text


def to_typst_us_decimal(value_us: float) -> str:
	"""Convert microseconds to Typst math as plain decimal text."""
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


def build_typst_table(rows: list[dict[str, str]], caption: str) -> str:
	lines = [
		"#figure(",
		"  align(center)[#table(",
		"    columns: 2,",
		"    align: (auto, auto),",
		"    table.header([データサイズ], [平均片道時間[μs]]),",
		"    table.hline(),",
	]

	for row in rows:
		size_bytes = int(float(row["DataSize_Bytes"]))
		time_us = float(row["Time_sec"]) * 1_000_000
		size_label = format_size_label(size_bytes)
		lines.append(f"    [{size_label}], [{to_typst_us_decimal(time_us)}],")

	lines.extend([
		"  )],",
		f"  caption: [{caption}],",
		"  kind: table",
		")",
	])
	return "\n".join(lines) + "\n"


def main() -> None:
	parser = argparse.ArgumentParser(description="MPI ping-pong CSVをTypst表へ変換します。")
	parser.add_argument("csv_path", nargs="?", default="mpi_pingpong.csv", help="入力CSVパス")
	args = parser.parse_args()

	csv_path = Path(args.csv_path)
	rows = read_rows(csv_path)
	if not rows:
		print("データが見つかりません。")
		return

	rows.sort(key=lambda r: int(float(r["DataSize_Bytes"])))
	typst_content = build_typst_table(rows, "MPI Ping-Pong 測定結果")

	output_path = Path(__file__).parent / f"{csv_path.stem}.typ"
	output_path.write_text(typst_content, encoding="utf-8")
	print(f"Typstファイルを保存しました: {output_path}")


if __name__ == "__main__":
	main()