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


def main():
    # コマンドライン引数の処理
    if len(sys.argv) != 3:
        print("Usage: python generate_pdf_congestion.py <input_csv> <output_pdf>")
        sys.exit(1)
    
    input_csv = sys.argv[1]
    output_pdf = sys.argv[2]
    
    # CSVを読み込む
    df = pd.read_csv(input_csv)
    
    # 通信時間を秒からマイクロ秒（μs）に変換
    df['AvgTime_us'] = df['AvgTime_sec'] * 1e6
    
    # 抽出するデータサイズを定義（3種類）
    selected_sizes = [8, 16384, 1048576]  # 8 B, 16 KB, 1 MB
    size_labels = {8: "8 Bytes", 16384: "16 KB", 1048576: "1 MB"}
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c']
    markers = ['o', 's', '^']
    
    # グラフを作成
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # 各データサイズごとに折れ線グラフを描画
    for size, color, marker in zip(selected_sizes, colors, markers):
        data = df[df['DataSize_Bytes'] == size].sort_values('Processes')
        if len(data) > 0:
            ax.loglog(
                data['Processes'],
                data['AvgTime_us'],
                marker=marker,
                color=color,
                linewidth=2,
                markersize=8,
                label=size_labels[size]
            )
    
    # 軸ラベルと設定（日本語）
    ax.set_xlabel('プロセス数(ペア数)', fontsize=12)
    ax.set_ylabel('通信時間 (μs)', fontsize=12)
    ax.set_title('通信競合における通信時間の増加（縦軸：対数スケール）', fontsize=14)

    # 点が存在するプロセス数の位置に、数値の目盛りを表示
    process_ticks = sorted(df['Processes'].dropna().unique())
    ax.set_xticks(process_ticks)
    ax.set_xticklabels([str(int(p)) for p in process_ticks])
    
    # グリッド線を追加（細かい線を含む）
    ax.grid(True, which="both", ls="--", alpha=0.7)
    
    # 凡例を配置
    ax.legend(fontsize=14, loc='upper left')
    
    # PDFとして保存
    plt.savefig(output_pdf, format='pdf', bbox_inches='tight')
    print(f"Graph saved to {output_pdf}")


if __name__ == '__main__':
    main()