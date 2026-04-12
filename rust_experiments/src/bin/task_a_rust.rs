use rayon::prelude::*;
use std::time::Instant;

fn main() {
    let n = 100_000_000;
    
    // 1.0 で埋められた1億個の要素を持つ配列（ベクタ）を作成
    // ※これは計測時間外（準備）です
    let a: Vec<f64> = vec![1.0; n];

    // 計測開始
    let start = Instant::now();

    // 並列処理による総和計算
    // 通常のイテレータ `iter()` を `par_iter()` に変えるだけ！
    let s: f64 = a.par_iter().sum();

    // 計測終了
    let duration = start.elapsed();

    // 結果出力
    println!("=== OpenMP vs Rayon (Rust) ===");
    println!("[Task A] Sum: {:.6}, Time: {:.6} sec", s, duration.as_secs_f64());
}