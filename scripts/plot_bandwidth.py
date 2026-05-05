# /// script
# requires-python = ">=3.12"
# ///
import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


def _resolve_time_column(df: pd.DataFrame) -> str:
    if "AvgTime_sec" in df.columns:
        return "AvgTime_sec"
    if "Time_sec" in df.columns:
        return "Time_sec"
    raise ValueError("CSVに AvgTime_sec または Time_sec 列が見つかりません。")


def _resolve_output_pair(output_pdf: Path) -> tuple[Path, Path]:
    """Return non-conflicting (pdf, png) paths with the same stem."""
    output_pdf = output_pdf.with_suffix(".pdf")
    parent = output_pdf.parent
    stem = output_pdf.stem

    index = 0
    while True:
        suffix = "" if index == 0 else f"_v{index + 1}"
        candidate_pdf = parent / f"{stem}{suffix}.pdf"
        candidate_png = parent / f"{stem}{suffix}.png"
        if not candidate_pdf.exists() and not candidate_png.exists():
            return candidate_pdf, candidate_png
        index += 1


def plot_bandwidth(csv_path: Path, output_pdf: Path) -> None:
    df = pd.read_csv(csv_path)

    if "DataSize_Bytes" not in df.columns:
        raise ValueError("CSVに DataSize_Bytes 列が見つかりません。")

    time_col = _resolve_time_column(df)

    df = df.copy()
    df["DataSize_Bytes"] = pd.to_numeric(df["DataSize_Bytes"], errors="coerce")
    df[time_col] = pd.to_numeric(df[time_col], errors="coerce")
    df = df.dropna(subset=["DataSize_Bytes", time_col])
    df = df[df["DataSize_Bytes"] > 0]
    df = df[df[time_col] > 0]

    # Bandwidth_MBps = (DataSize_Bytes / 10^6) / AvgTime_sec
    df["Bandwidth_MBps"] = (df["DataSize_Bytes"] / 1_000_000.0) / df[time_col]

    # 同じデータサイズが複数行ある場合に備えて平均化
    grouped = (
        df.groupby("DataSize_Bytes", as_index=False)["Bandwidth_MBps"]
        .mean()
        .sort_values("DataSize_Bytes")
    )

    plt.figure(figsize=(10, 6))
    plt.plot(
        grouped["DataSize_Bytes"],
        grouped["Bandwidth_MBps"],
        marker="o",
        linewidth=2.0,
        markersize=5,
        color="#1f77b4",
    )

    plt.xscale("log")
    plt.xlabel("Data Size (Bytes)")
    plt.ylabel("Bandwidth (MB/s)")
    plt.title("MPI Communication Bandwidth vs Data Size")
    plt.grid(True, which="both", linestyle="--", linewidth=0.7, alpha=0.6)
    plt.tight_layout()

    resolved_pdf, resolved_png = _resolve_output_pair(output_pdf)
    resolved_pdf.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(resolved_pdf, format="pdf", dpi=300, bbox_inches="tight")
    plt.savefig(resolved_png, format="png", dpi=300, bbox_inches="tight")
    plt.close()

    print(f"Bandwidth graph saved (PDF): {resolved_pdf}")
    print(f"Bandwidth graph saved (PNG): {resolved_png}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="5.2(a) のCSVからデータサイズに対するバンド幅グラフを作成します。"
    )
    parser.add_argument("input_csv", type=Path, help="入力CSVパス")
    parser.add_argument("output_pdf", type=Path, help="出力PDFパス")
    args = parser.parse_args()

    plot_bandwidth(args.input_csv, args.output_pdf)


if __name__ == "__main__":
    main()
