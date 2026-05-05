# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pandas>=2.1.0",
#     "matplotlib>=3.10.8",
#     "japanize-matplotlib>=1.1.3",
#     "setuptools>=82.0.1",
# ]
# ///
import sys
import pandas as pd
import matplotlib.pyplot as plt
import japanize_matplotlib


FONT_SIZE_TITLE = 24
FONT_SIZE_AXIS_LABEL = 22
FONT_SIZE_TICKS = 14
FONT_SIZE_LEGEND = 16


def main():
    # コマンドライン引数の処理
    if len(sys.argv) != 3:
        print("Usage: python generate_pdf_congestion.py <input_csv> <output_pdf>")
        sys.exit(1)
    
    input_csv = sys.argv[1]
    output_pdf = sys.argv[2]
    
    # CSVを読み込む
    df = pd.read_csv(input_csv)
    
    # 平均通信時間[s]から総バンド幅[GB/s]へ変換
    df = df[df['AvgTime_sec'] > 0].copy()
    df['Total_Bandwidth_GBps'] = (df['DataSize_Bytes'] / 1_000_000_000 / df['AvgTime_sec']) * (df['Processes'] / 2)
    
    # 抽出するデータサイズを定義（3種類）
    selected_sizes = [8, 16384, 1048576, 16777216]  # 8 B, 16 KB, 1 MB, 16 MB
    size_labels = {8: "8 Bytes", 16384: "16 KB", 1048576: "1 MB", 16777216: "16 MB"}
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']
    markers = ['o', 's', '^', 'D']
    
    # グラフを作成
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # 各データサイズごとに折れ線グラフを描画
    for size, color, marker in zip(selected_sizes, colors, markers):
        data = df[df['DataSize_Bytes'] == size].sort_values('Processes')
        if len(data) > 0:
            ax.loglog(
                data['Processes'],
                data['Total_Bandwidth_GBps'],
                marker=marker,
                color=color,
                linewidth=2,
                markersize=8,
                label=size_labels[size]
            )
    
    # 軸ラベルと設定（日本語）
    ax.set_xlabel('プロセス数', fontsize=FONT_SIZE_AXIS_LABEL)
    ax.set_ylabel('合計バンド幅 [GB/s]', fontsize=FONT_SIZE_AXIS_LABEL)
    ax.set_title('通信競合における合計バンド幅の推移', fontsize=FONT_SIZE_TITLE)

    ax.set_xscale('log', base=2)
    ax.set_yscale('linear')

    # 点が存在するプロセス数の位置に、数値の目盛りを表示
    process_ticks = sorted(df['Processes'].dropna().unique())
    ax.set_xticks(process_ticks)
    ax.set_xticklabels([str(int(p)) for p in process_ticks], fontsize=FONT_SIZE_TICKS)
    ax.tick_params(axis='y', labelsize=FONT_SIZE_TICKS)
    
    # グリッド線を追加（細かい線を含む）
    ax.grid(True, which="both", ls="--", alpha=0.7)
    
    # 凡例を配置
    ax.legend(fontsize=FONT_SIZE_LEGEND, loc='upper left')
    
    # PDFとして保存
    plt.savefig(output_pdf, format='pdf', bbox_inches='tight')
    print(f"Graph saved to {output_pdf}")


if __name__ == '__main__':
    main()