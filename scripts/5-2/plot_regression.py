# /// script
# requires-python = ">=3.12"
# dependencies = ["matplotlib", "japanize-matplotlib", "setuptools"]
# ///
import argparse
from pathlib import Path

import japanize_matplotlib  # noqa: F401
import matplotlib.pyplot as plt

from estimate_pingpong_model import estimate_a_b, read_series


FONT_SIZE_TITLE = 24
FONT_SIZE_AXIS_LABEL = 24
FONT_SIZE_TICKS = 20
FONT_SIZE_LEGEND = 18
FONT_SIZE_COEF = 18


def format_sig4(value: float) -> str:
	if value == 0.0:
		return "0"
	return f"{value:.4g}"


def plot_regression(
	crossnode_csv_path: Path,
	local_csv_path: Path,
	output_pdf: Path,
	scale: str,
	small_min: int,
	small_max: int,
	small_points: int,
	large_min: int,
) -> None:
	cross_series = read_series(crossnode_csv_path)
	local_series = read_series(local_csv_path)

	cross_a_sec, cross_b_sec_per_byte, cross_b_gbps = estimate_a_b(
		cross_series,
		small_min_bytes=small_min,
		small_max_bytes=small_max,
		small_points=small_points,
		large_min_bytes=large_min,
	)
	local_a_sec, local_b_sec_per_byte, local_b_gbps = estimate_a_b(
		local_series,
		small_min_bytes=small_min,
		small_max_bytes=small_max,
		small_points=small_points,
		large_min_bytes=large_min,
	)

	cross_sizes = [n for n, _ in cross_series]
	cross_times_us = [t * 1_000_000 for _, t in cross_series]
	cross_times_pred_us = [
		(cross_a_sec + cross_b_sec_per_byte * n) * 1_000_000 for n in cross_sizes
	]

	local_sizes = [n for n, _ in local_series]
	local_times_us = [t * 1_000_000 for _, t in local_series]
	local_times_pred_us = [
		(local_a_sec + local_b_sec_per_byte * n) * 1_000_000 for n in local_sizes
	]

	fig, ax = plt.subplots(figsize=(12, 7))
	ax.scatter(
		cross_sizes,
		cross_times_us,
		label="ノード間 実測値",
		color="#d62728",
		s=34,
		alpha=0.85,
		zorder=3,
	)
	ax.plot(
		cross_sizes,
		cross_times_pred_us,
		label="ノード間 近似直線(T = a + b*N)",
		color="#d62728",
		linewidth=2.1,
		linestyle="-",
		zorder=4,
	)

	ax.scatter(
		local_sizes,
		local_times_us,
		label="ノード内 実測値",
		color="#1f77b4",
		s=34,
		alpha=0.85,
		zorder=3,
	)
	ax.plot(
		local_sizes,
		local_times_pred_us,
		label="ノード内 近似直線(T = a + b*N)",
		color="#1f77b4",
		linewidth=2.1,
		linestyle="-",
		zorder=4,
	)

	ax.set_xlabel("データサイズ N [Bytes]", fontsize=FONT_SIZE_AXIS_LABEL)
	ax.set_ylabel("平均通信時間 T [μs]", fontsize=FONT_SIZE_AXIS_LABEL)
	ax.tick_params(axis="both", which="both", labelsize=FONT_SIZE_TICKS)

	ax.set_title("Ping-Pong通信性能評価(ノード間・ノード内)", fontsize=FONT_SIZE_TITLE)

	cross_a_str = format_sig4(cross_a_sec)
	cross_b_str = format_sig4(cross_b_sec_per_byte)
	cross_bg_str = format_sig4(cross_b_gbps)
	local_a_str = format_sig4(local_a_sec)
	local_b_str = format_sig4(local_b_sec_per_byte)
	local_bg_str = format_sig4(local_b_gbps)
	coef_text = (
		"ノード間: "
		f"a={cross_a_str} s, b={cross_b_str} s/Byte "
		f"(実効バンド幅: {cross_bg_str} GB/s)\n"
		"ノード内: "
		f"a={local_a_str} s, b={local_b_str} s/Byte "
		f"(実効バンド幅: {local_bg_str} GB/s)"
	)
	ax.text(
		0.02,
		0.98,
		coef_text,
		transform=ax.transAxes,
		va="top",
		ha="left",
		fontsize=FONT_SIZE_COEF,
		bbox={"facecolor": "white", "alpha": 0.85, "edgecolor": "#cccccc"},
	)

	if scale == "loglog":
		ax.set_xscale("log")
		ax.set_yscale("log")
	else:
		ax.set_xscale("linear")
		ax.set_yscale("linear")

	ax.grid(True, linestyle="--", alpha=0.35)
	ax.legend(loc="best", fontsize=FONT_SIZE_LEGEND)
	fig.tight_layout()
	fig.savefig(output_pdf, format="pdf", dpi=300, bbox_inches="tight")

	print(f"Saved to: {output_pdf} ({scale} scale)")
	print(f"[Cross Node] a={cross_a_str} s, b={cross_b_str} s/Byte, bandwidth={cross_bg_str} GB/s")
	print(f"[Local Node] a={local_a_str} s, b={local_b_str} s/Byte, bandwidth={local_bg_str} GB/s")


def main() -> None:
	parser = argparse.ArgumentParser(
		description="ノード間・ノード内を同一グラフで、estimate_pingpong_model.py と同じ推定法で重ね描画する"
	)
	parser.add_argument("crossnode_csv", type=Path, help="ノード間CSV (DataSize_Bytes と AvgTime_sec または Time_sec)")
	parser.add_argument("local_csv", type=Path, help="ノード内CSV (DataSize_Bytes と AvgTime_sec または Time_sec)")
	parser.add_argument("output", type=Path, help="出力PDF")
	parser.add_argument("--scale", choices=["linear", "loglog"], default="linear")
	parser.add_argument("--small-min", type=int, default=8)
	parser.add_argument("--small-max", type=int, default=32)
	parser.add_argument("--small-points", type=int, default=3)
	parser.add_argument("--large-min", type=int, default=1_048_576)
	args = parser.parse_args()

	plot_regression(
		crossnode_csv_path=args.crossnode_csv,
		local_csv_path=args.local_csv,
		output_pdf=args.output,
		scale=args.scale,
		small_min=args.small_min,
		small_max=args.small_max,
		small_points=args.small_points,
		large_min=args.large_min,
	)


if __name__ == "__main__":
	main()
