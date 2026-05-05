# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
import argparse
import csv
import sys
from pathlib import Path


PATTERNS = (
	("Flat MPI", 28, 1, "28proc\n×1thrd"),
	("Hybrid", 4, 7, "4proc\n×7thrd"),
	("Pure Hybrid", 1, 28, "1proc\n×28thrd"),
)


def read_rows(csv_path: Path) -> list[dict[str, str]]:
	with csv_path.open("r", encoding="utf-8", newline="") as handle:
		return list(csv.DictReader(handle))


def to_int(value: str) -> int:
	return int(float(value))


def format_time(value: float) -> str:
	return f"${value:.2f}$"


def format_ratio(value: float) -> str:
	return f"${value:.2f}$"


def format_gips(value: float) -> str:
	return f"${value:.2f}$"


def select_series(rows: list[dict[str, str]], num_particles: int, per_node_mpi: int, omp_threads: int) -> list[dict[str, str]]:
	selected = [
		row
		for row in rows
		if to_int(row["NumParticles"]) == num_particles
		and to_int(row["MPI_Processes"]) == to_int(row["Nodes"]) * per_node_mpi
		and to_int(row["OpenMP_Threads"]) == omp_threads
	]
	return sorted(selected, key=lambda row: to_int(row["Nodes"]))


def build_typst_table(rows: list[dict[str, str]]) -> str:
	lines = [
		"#table(",
		"  columns: 7,",
		"  align: (auto, auto, right, right, right, right, right),",
		"  table.header([データサイズ N], [パターン], [ノード数], [実行時間 [s]], [速度向上率 $S(p)$], [並列化効率 $E(p)$], [実効性能 [GIPS]]),",
		"  table.hline(),",
	]

	unique_particles = sorted({to_int(row["NumParticles"]) for row in rows})
	for num_particles in unique_particles:
		pattern_series_list = []
		for _pattern_name, per_node_mpi, omp_threads, label in PATTERNS:
			series = select_series(rows, num_particles, per_node_mpi, omp_threads)
			if not series:
				continue

			baseline = next((row for row in series if to_int(row["Nodes"]) == 1), None)
			if baseline is None:
				continue

			baseline_time = float(baseline["Time_sec"])
			pattern_series_list.append((label, series, baseline_time))

		if not pattern_series_list:
			continue

		total_rows_in_block = sum(len(series) for _label, series, _baseline_time in pattern_series_list)
		first_particle_row = True
		for label, series, baseline_time in pattern_series_list:
			pattern_rowspan = len(series)
			for index, row in enumerate(series):
				nodes = to_int(row["Nodes"])
				time_sec = float(row["Time_sec"])
				speedup = baseline_time / time_sec
				efficiency = speedup / nodes
				gips = (num_particles * (num_particles - 1) * 1000) / (time_sec * 1e9)
				cells = []
				if first_particle_row and index == 0:
					cells.append(f"table.cell(rowspan: {total_rows_in_block})[{num_particles}]")
				if index == 0:
					cells.append(f"table.cell(rowspan: {pattern_rowspan})[{label}]")
				cells.extend(
					[
						f"[{nodes}]",
						f"[{format_time(time_sec)}]",
						f"[{format_ratio(speedup)}]",
						f"[{format_ratio(efficiency)}]",
						f"[{format_gips(gips)}]",
					]
				)
				lines.append(
					"  " + ", ".join(cells) + ","
				)
				if first_particle_row and index == 0:
					first_particle_row = False

	lines.append(")")
	return "\n".join(lines) + "\n"


def pick_num_particles(rows: list[dict[str, str]], requested: int | None) -> int:
	unique_particles = sorted({to_int(row["NumParticles"]) for row in rows})
	if not unique_particles:
		raise ValueError("CSVにNumParticlesのデータがありません。")
	if requested is None:
		return unique_particles[0]
	if requested not in unique_particles:
		raise ValueError(f"指定した NumParticles={requested} のデータが見つかりません。")
	return requested


def main() -> None:
	parser = argparse.ArgumentParser(description="nbody_hybrid CSVをTypst表へ変換します。")
	parser.add_argument("input_csv", help="入力CSVファイル (例: data/5-4/nbody_hybrid.csv)")
	parser.add_argument("output_typ", help="出力Typstファイル (例: assets/5-4/nbody_hybrid_896.typ)")
	args = parser.parse_args()

	input_path = Path(args.input_csv)
	output_path = Path(args.output_typ)

	if not input_path.exists():
		print(f"Error: input CSV not found: {input_path}")
		sys.exit(1)

	rows = read_rows(input_path)
	if not rows:
		print("データが見つかりません。")
		sys.exit(1)

	typst_content = build_typst_table(rows)
	output_path.parent.mkdir(parents=True, exist_ok=True)
	output_path.write_text(typst_content, encoding="utf-8")
	print(f"Typstファイルを保存しました: {output_path}")


if __name__ == "__main__":
	main()
