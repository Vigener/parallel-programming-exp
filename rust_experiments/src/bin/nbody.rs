use rayon::prelude::*;
use std::{env, time::Instant};
use rand::RngExt; // 乱数生成用

// 星の設計図（#[derive(Clone, Copy)] がRust特有の魔法）
#[derive(Clone, Copy)]
struct Particle {
    mass: f64,
    x: f64, y: f64, z: f64,
    vx: f64, vy: f64, vz: f64,
}

fn main() {
    // コマンドライン引数からNを取得。無ければデフォルト10000。
    let mut n = 10000;
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        n = args[1].parse::<usize>().unwrap_or(10000);
    }
    
    let steps = 10;
    let dt = 0.01;
    let g = 1.0;

    let mut rng = rand::rng();

    // 宇宙の初期化（ランダムな位置と質量）
    let mut particles = vec![
        Particle {
            mass: rng.random_range(1.0..2.0),
            x: rng.random_range(0.0..100.0),
            y: rng.random_range(0.0..100.0),
            z: rng.random_range(0.0..100.0),
            vx: 0.0, vy: 0.0, vz: 0.0,
        };
        n
    ];

    let start = Instant::now();

    // タイムステップのループ
    for _ in 0..steps {
        // 現在の宇宙をまるごとコピーして、次のキャンバスを作る
        let mut next_particles = particles.clone();

        // 並列化（仕事泥棒）で各星を計算し、キャンバス(next_particles)を更新する
        next_particles.par_iter_mut().enumerate().for_each(|(i, next_p)| {
            let mut ax = 0.0;
            let mut ay = 0.0;
            let mut az = 0.0;

            for j in 0..n {
                if i == j { continue; }

                // 現在の宇宙(particles)から、星iと星jのデータを読み取る
                let p_i = &particles[i];
                let p_j = &particles[j];

                let dx = p_j.x - p_i.x;
                let dy = p_j.y - p_i.y;
                let dz = p_j.z - p_i.z;

                let dist_sq = dx * dx + dy * dy + dz * dz + 1e-9;
                let dist = dist_sq.sqrt();

                let force_mag = g * p_j.mass / dist_sq;

                ax += force_mag * (dx / dist);
                ay += force_mag * (dy / dist);
                az += force_mag * (dz / dist);
            }

            // 次のキャンバス(next_p)の速度と位置を更新
            next_p.vx = particles[i].vx + ax * dt;
            next_p.vy = particles[i].vy + ay * dt;
            next_p.vz = particles[i].vz + az * dt;

            next_p.x = particles[i].x + next_p.vx * dt;
            next_p.y = particles[i].y + next_p.vy * dt;
            next_p.z = particles[i].z + next_p.vz * dt;
        });

        // 宇宙を上書きして次の時間へ
        particles = next_particles;
    }

    let duration = start.elapsed();
    println!("particles={}, steps={}, time={:.6} sec", n, steps, duration.as_secs_f64());
}