use rayon::prelude::*;
use std::time::Instant;

fn main() {
    let n = 40000;
    // 結果を格納する4万個の配列
    let mut results = vec![0.0; n];

    let start = Instant::now();

    // par_iter_mut() で並列に変更。enumerate() でインデックス i を取得。
    // ※Rayonが「仕事泥棒」を自動発動して、暇なスレッドが忙しいスレッドを助ける
    results.par_iter_mut().enumerate().for_each(|(i, res)| {
        let mut sum: f64 = 0.0;
        for j in 0..i {
            sum += f64::sin(j as f64 * 0.01);
        }
        *res = sum;
    });

    let duration = start.elapsed();
    println!("=== Rayon (Work-Stealing) ===");
    println!("Time: {:.6} sec", duration.as_secs_f64());
}