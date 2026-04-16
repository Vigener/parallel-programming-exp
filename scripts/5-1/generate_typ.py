# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
import csv
import sys
from pathlib import Path


TARGET_NS = {"1000000", "10000000", "100x100", "1000x1000"}
TASK_ORDER = ["A_Int", "A_Float", "B", "C"]
N_ORDER = ["1000000", "10000000", "100x100", "1000x1000"]

def read_csv(filename):
    with open(filename, "r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def to_typst_scientific(value):
    """Return Typst math scientific notation like $1.23 * 10^{-6}$."""
    val = float(value)
    if val == 0:
        return "$0$"

    scientific = f"{val:.2e}"  # e.g. 1.23e-06
    mantissa_str, exponent_str = scientific.split("e")
    mantissa = float(mantissa_str)
    exponent = int(exponent_str)
    return f"${mantissa:.2f} * 10^{{{exponent}}}$"


def build_task_table(task_name, n_value, rows):
    if not rows:
        return ""

    lines = [
        "#figure(",
        "  align(center)[#table(",
        "    columns: 2,",
        "    align: (auto, auto),",
        "    table.header([スレッド数], [平均時間[sec]]),",
        "    table.hline(),",
    ]

    for row in rows:
        thread = int(float(row["Threads"]))
        avg_time = to_typst_scientific(row["AvgTime(sec)"])
        lines.append(f"    [{thread}], [{avg_time}],")

    lines.extend([
        "  )],",
        f"  caption: [Task: {task_name} (N={n_value})],",
        "  kind: table",
        ")",
    ])
    return "\n".join(lines)

def main():
    # 引数が足りない場合のエラーハンドリング（ノイズ排除）
    if len(sys.argv) < 2:
        print("Usage: uv run plot_graph.py <input_csv_path> [output_pdf_path]")
        sys.exit(1)

    input_csv = Path(sys.argv[1])
    output_pdf = Path(sys.argv[2]) if len(sys.argv) >= 3 else input_csv.with_suffix(".pdf")
    
    # filename = "openmp_tasks_constN_run5.csv"
    # data = read_csv(filename)
    data = read_csv(input_csv)
    if not data:
        print("データが見つかりません。")
        return

    filtered = [
        row
        for row in data
        if row.get("N", "").strip() in TARGET_NS and row.get("Task", "") in TASK_ORDER
    ]

    grouped = {(task, n_value): [] for task in TASK_ORDER for n_value in N_ORDER}
    for row in filtered:
        key = (row["Task"], row["N"].strip())
        if key in grouped:
            grouped[key].append(row)

    tables = []
    for task in TASK_ORDER:
        for n_value in N_ORDER:
            rows = grouped[(task, n_value)]
            if not rows:
                continue
            rows.sort(key=lambda r: int(float(r["Threads"])))
            table_content = build_task_table(task, n_value, rows)
            if table_content:
                tables.append(table_content)

    if not tables:
        print("書き出すテーブルがありません。")
        return

    output_dir = output_pdf if output_pdf.suffix == "" else output_pdf.parent
    output_dir.mkdir(parents=True, exist_ok=True)
    output_typ = output_dir / f"{output_pdf.stem}.typ"
    output_typ.write_text("\n\n".join(tables) + "\n", encoding="utf-8")
    print(f"Typstファイルを保存しました: {output_typ}")

if __name__ == "__main__":
    main()