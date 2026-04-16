# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pandas>=3.0.2",
# ]
# ///
import argparse
from pathlib import Path

import pandas as pd


def format_n_label(n_value: str, keep_matrix_notation: bool) -> str:
	n_text = str(n_value).strip()
	if keep_matrix_notation or "x" in n_text.lower():
		return n_text
	if n_text.isdigit() and n_text.startswith("1") and set(n_text[1:]) <= {"0"}:
		exponent = len(n_text) - 1
		return rf"$10^{exponent}$"
	return n_text


def format_ms(value_ms: float) -> str:
	"""Convert milliseconds to plain Typst text."""
	if value_ms == 0:
		return "$0$"
	if value_ms < 10:
		text = f"{value_ms:.3f}"
	else:
		text = f"{value_ms:.2f}"
	return f"${text}$"


def build_typst_table_single_task(df: pd.DataFrame, task: str, n_value: str, title: str, keep_matrix_notation: bool) -> str:
	series = df[(df["Task"] == task) & (df["N"] == n_value)].copy()
	if series.empty:
		raise ValueError(f"{task} の N={n_value} に対応するデータがありません。")

	series["Threads"] = pd.to_numeric(series["Threads"], errors="coerce")
	series["Time_ms"] = pd.to_numeric(series["Time_ms"], errors="coerce")
	series = series.dropna(subset=["Threads", "Time_ms"]).sort_values("Threads")

	lines = [
		"#figure(",
		"  align(center)[#table(",
		"    columns: 2,",
		"    align: (auto, right),",
		"    table.header([スレッド数], [平均時間[ms]]),",
		"    table.hline(),",
	]

	for _, row in series.iterrows():
		threads = int(row["Threads"])
		lines.append(f"    [{threads}], [{format_ms(float(row['Time_ms']))}],")

	display_n = format_n_label(n_value, keep_matrix_notation)
	lines.extend([
		"  )],",
		f"  caption: [{title} (N={display_n})],",
		"  kind: table",
		")",
	])
	return "\n".join(lines) + "\n"


def main() -> None:
	parser = argparse.ArgumentParser(description="OpenMP計測CSVからTypst表を生成します。")
	parser.add_argument("csv_path", type=Path, help="入力CSVファイルパス")
	parser.add_argument(
		"--n",
		dest="n_groups",
		action="append",
		nargs="+",
		metavar="N",
		help="出力ごとに使うNを複数指定します。指定順は A, B, C です。各グループ内では1つのNにつき1つの.typを出力します。",
	)
	args = parser.parse_args()

	csv_path = args.csv_path
	df = pd.read_csv(csv_path, skipinitialspace=True)
	df["N"] = df["N"].astype(str).str.strip()
	if "AvgTime(sec)" in df.columns:
		df["Time_ms"] = pd.to_numeric(df["AvgTime(sec)"], errors="coerce") * 1000
	elif "Time(sec)" in df.columns:
		df["Time_ms"] = pd.to_numeric(df["Time(sec)"], errors="coerce") * 1000
	else:
		raise ValueError("時間列が見つかりません。AvgTime(sec) か Time(sec) が必要です。")

	plot_specs = [
		{
			"key": "B",
			"title": "課題5-1 B の平均時間比較",
			"tasks": ["B"],
			"default_ns": ["1000000", "10000000"],
			"output_suffix": "B",
			"keep_matrix_notation": False,
		},
		{
			"key": "C",
			"title": "課題5-1 C の平均時間比較",
			"tasks": ["C"],
			"default_ns": ["100x100", "1000x1000"],
			"output_suffix": "C",
			"keep_matrix_notation": True,
		},
	]

	default_n_groups = [spec["default_ns"] for spec in plot_specs]
	provided_n_groups = args.n_groups or []
	if len(provided_n_groups) > len(plot_specs):
		raise ValueError("`--n` は最大 2 回まで指定できます。指定順は B, C です。")

	for index, spec in enumerate(plot_specs):
		plot_ns = provided_n_groups[index] if index < len(provided_n_groups) else default_n_groups[index]
		plot_ns = [str(value).strip() for value in plot_ns]
		sub_df = df[df["N"].isin(plot_ns)].copy()
		if sub_df.empty:
			print(f"{spec['key']} のデータが無いためスキップしました。")
			continue

		for target_n in plot_ns:
			group_df = sub_df[sub_df["N"] == target_n].copy()
			if group_df.empty:
				print(f"{spec['key']} の N={target_n} のデータが無いためスキップしました。")
				continue

			for task in spec["tasks"]:
				if group_df[group_df["Task"] == task].empty:
					print(f"{spec['key']} の N={target_n} に描画できるデータが無いためスキップしました。")
					break
			else:
				content = build_typst_table_single_task(
					group_df,
					task=spec["tasks"][0],
					n_value=target_n,
					title=spec["title"],
					keep_matrix_notation=spec["keep_matrix_notation"],
				)
				output_path = csv_path.with_name(f"{csv_path.stem}_{spec['output_suffix']}_N-{target_n}.typ")
				output_path.write_text(content, encoding="utf-8")
				print(f"Typstファイルを保存しました: {output_path}")


if __name__ == "__main__":
	main()
