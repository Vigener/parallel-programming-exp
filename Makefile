.PHONY: 5-1 5-1-pdf 5-1-table 5-2-pdf-regression 5-2-pdf-collective clean

PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# --- 個別のサブタスク ---

# グラフだけを生成（修正した時用）
5-1-pdf:
	uv run scripts/5-1/generate_pdf.py data/5-1/openmp_tasks_constN_run5.csv assets/5-1/graph_tasks.pdf
	uv run scripts/5-1/generate_pdf_a.py data/5-1/openmp_tasks_constN_run5.csv assets/5-1/table_tasks_a.pdf

# 表だけを生成（修正した時用）
5-1-typ:
	uv run scripts/5-1/generate_typ.py data/5-1/openmp_tasks_constN_run5.csv assets/5-1/table_tasks.typ

# 5-2-plot-pingpong:
# 	uv run scripts/5-2/plot_graph_pingpong.py data/5-2/mpi_pingpong_local.csv data/5-2/mpi_pingpong_crossnode.csv assets/5-2/graph_pingpong.pdf

# 5-2-table-pingpong:
# 	uv run scripts/5-2/generate_table_pingpong.py data/5-2/mpi_pingpong_local.csv assets/5-2/table_pingpong_local.typ
# 	uv run scripts/5-2/generate_table_pingpong.py data/5-2/mpi_pingpong_crossnode.csv assets/5-2/table_pingpong_crossnode.typ

5-2-pdf-collective:
	uv run $(PROJECT_ROOT)/scripts/5-2/plot_graph_collective.py $(PROJECT_ROOT)/data/5-2/mpi_collective_112.csv --pingpong-csv $(PROJECT_ROOT)/data/5-2/mpi_pingpong_crossnode.csv --output1 $(PROJECT_ROOT)/assets/5-2/mpi_collective_size_vs_bandwidth.pdf --output2 $(PROJECT_ROOT)/assets/5-2/mpi_collective_procs_vs_time.pdf

# 5-2-table-collective:
# 	uv run scripts/5-2/generate_table_collective.py data/5-2/mpi_collective_112.csv data/5-2/mpi_pingpong_crossnode.csv assets/5-2/table_collective.typ

5-2-typ:
	uv run scripts/5-2/generate_typ_congestion.py data/5-2/mpi_congestion.csv assets/5-2/mpi_congestion.typ

5-2-pdf:
	uv run scripts/5-2/generate_pdf_congestion.py data/5-2/mpi_congestion.csv assets/5-2/mpi_congestion.pdf

# 5.2(a) 回帰直線プロット（線形軸と両対数軸）
5-2-pdf-regression:
	uv run scripts/5-2/plot_regression.py data/5-2/mpi_pingpong_crossnode.csv data/5-2/mpi_pingpong_local.csv assets/5-2/mpi_pingpong_regression_linear.pdf
	uv run scripts/5-2/plot_regression.py --scale loglog data/5-2/mpi_pingpong_crossnode.csv data/5-2/mpi_pingpong_local.csv assets/5-2/mpi_pingpong_regression_loglog.pdf

5-2-pdf-pingpong:
	uv run scripts/5-2/plot_graph_pingpong.py data/5-2/mpi_pingpong_local.csv data/5-2/mpi_pingpong_crossnode.csv --output assets/5-2/mpi_pingpong_comparison_loglinear_bandwidth_vs_size.pdf

5-2-pdf-congestion:
	uv run scripts/5-2/plot_graph_congestion.py data/5-2/mpi_congestion.csv assets/5-2/mpi_congestion_2nodes.pdf

5-2-typ-congestion:
	uv run scripts/5-2/generate_typ_congestion.py data/5-2/mpi_congestion.csv assets/5-2/mpi_congestion_2nodes.typ

5-4-pdf-896:
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_896.pdf --num-particles 896

5-4-pdf-2688:
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_2688.pdf --num-particles 2688

5-4-pdf-8960:
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_8960.pdf --num-particles 8960

5-4-pdf-26880:
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_26880.pdf --num-particles 26880

5-4-pdf-all:
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_896.pdf --num-particles 896
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_2688.pdf --num-particles 2688
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_8960.pdf --num-particles 8960
	uv run scripts/5-4/plot_graph_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid_26880.pdf --num-particles 26880

5-4-typ:
	uv run scripts/5-4/generate_table_nbody_hybrid.py data/5-4/nbody_hybrid.csv assets/5-4/nbody_hybrid.typ

# --- 掃除 ---
clean:
	rm -f */*.pdf */*.typ