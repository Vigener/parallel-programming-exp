# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pandas>=3.0.2",
# ]
# ///
import argparse
from pathlib import Path

import pandas as pd


def format_n_label(n_value: str) -> str:
	n_text = str(n_value).strip()
	if n_text.isdigit() and n_text.startswith("1") and set(n_text[1:]) <= {"0"}:
		exponent = len(n_text) - 1
		return rf"$10^{exponent}$"
	return n_text


def format_ms(value_sec: float) -> str:
	"""Convert seconds to plain milliseconds for Typst."""
	value_ms = value_sec * 1000
	if value_ms == 0:
		return "$0$"
	if value_ms < 10:
		text = f"{value_ms:.3f}"
	else:
		text = f"{value_ms:.2f}"
	return f"${text}$"


def build_typst_table(rows: pd.DataFrame, n_value: str) -> str:
	series = rows[rows["N"] == n_value].copy()
	if series.empty:
		raise ValueError(f"N={n_value} に対応するデータがありません。")

	series["Threads"] = pd.to_numeric(series["Threads"], errors="coerce")
	series["Time_ms"] = pd.to_numeric(series["Time_ms"], errors="coerce")
	series = series.dropna(subset=["Threads", "Time_ms"])

	by_thread = series.pivot_table(index="Threads", columns="Task", values="Time_ms", aggfunc="first").sort_index()

	lines = [
		"#figure(",
		"  align(center)[#table(",
		"    columns: 3,",
		"    align: (auto, right, right),",
		"    table.header([スレッド数], [A(整数) [ms]], [A(浮動小数) [ms]]),",
		"    table.hline(),",
	]

	for threads, values in by_thread.iterrows():
		int_value = values.get("A_Int")
		float_value = values.get("A_Float")
		int_text = format_ms(float(int_value)) if pd.notna(int_value) else "-"
		float_text = format_ms(float(float_value)) if pd.notna(float_value) else "-"
		lines.append(f"    [{int(threads)}], [{int_text}], [{float_text}],")

	display_n = format_n_label(n_value)
	lines.extend([
		"  )],",
		f"  caption: [Task: A(整数 / 浮動小数) (N={display_n})],",
		"  kind: table",
		")",
	])
	return "\n".join(lines) + "\n"


def main() -> None:
	parser = argparse.ArgumentParser(description="A専用のOpenMP計測CSVからTypst表を生成します。")
	parser.add_argument("csv_path", type=Path, help="入力CSVファイルパス")
	parser.add_argument(
		"--n",
		nargs="+",
		default=["1000000", "10000000"],
		help="A表に含めるNを複数指定します。",
	)
	args = parser.parse_args()

	csv_path = args.csv_path
	n_values = [str(v).strip() for v in args.n]

	df = pd.read_csv(csv_path, skipinitialspace=True)
	df["N"] = df["N"].astype(str).str.strip()
	if "AvgTime(sec)" in df.columns:
		df["Time_ms"] = pd.to_numeric(df["AvgTime(sec)"], errors="coerce") * 1000
	elif "Time(sec)" in df.columns:
		df["Time_ms"] = pd.to_numeric(df["Time(sec)"], errors="coerce") * 1000
	else:
		raise ValueError("時間列が見つかりません。AvgTime(sec) か Time(sec) が必要です。")

	df = df[df["Task"].isin(["A_Int", "A_Float"]) & df["N"].isin(n_values)].copy()
	df["Threads"] = pd.to_numeric(df["Threads"], errors="coerce")
	df = df.dropna(subset=["Threads", "Time_ms"])

	if df.empty:
		raise ValueError("指定条件に一致するA系データがありません。")

	for n_value in n_values:
		if df[df["N"] == n_value].empty:
			print(f"N={n_value} のデータが無いためスキップしました。")
			continue

		content = build_typst_table(df, n_value)
		output_path = csv_path.with_name(f"{csv_path.stem}_A_N-{n_value}.typ")
		output_path.write_text(content, encoding="utf-8")
		print(f"Typstファイルを保存しました: {output_path}")


if __name__ == "__main__":
	main()
