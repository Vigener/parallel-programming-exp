.PHONY: 5-1 5-1-pdf 5-1-table clean

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

# 5-2-plot-collective:
# 	uv run scripts/5-2/plot_graph_collective.py data/5-2/mpi_collective_112.csv --pingpong-csv data/5-2/mpi_pingpong_crossnode.csv assets/5-2/graph_collective.pdf

# 5-2-table-collective:
# 	uv run scripts/5-2/generate_table_collective.py data/5-2/mpi_collective_112.csv data/5-2/mpi_pingpong_crossnode.csv assets/5-2/table_collective.typ

5-2-typ:
	uv run scripts/5-2/generate_typ_congestion.py data/5-2/mpi_congestion.csv assets/5-2/mpi_congestion.typ

5-2-pdf:
	uv run scripts/5-2/generate_pdf_congestion.py data/5-2/mpi_congestion.csv assets/5-2/mpi_congestion.pdf


# --- 掃除 ---
clean:
	rm -f */*.pdf */*.typ