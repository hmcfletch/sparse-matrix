require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'lib', 'sparse-matrix' ) )
sizes = [5, 10, 25, 100, 250]#, 500, 1000]
# sizes = [250]
sparsities = [0.25, 0.1, 0.01, 0.001]
# sparsities = [0.01]
results = {}
num_runs = 3

sizes.each do |size|
  results[size] = {}
  sparsities.each do |sparsity|
    results[size][sparsity] = {}

    matrix_time = 0
    sparse_matrix_time = 0

    num_runs.times do |n|
      rows_a = {}
      rows_b = {}

      nnz = (size * size * sparsity).to_i

      nnz.times do |m|
        i_a = rand(size)
        j_a = rand(size)
        rows_a[i_a] ||= {}
        rows_a[i_a][j_a] = rand(5)

        i_b = rand(size)
        j_b = rand(size)
        rows_b[i_b] ||= {}
        rows_b[i_b][j_b] = rand(5)
      end

      s_a = SparseMatrix.rows(rows_a)
      # FIXME: figure out a better way to do this
      s_a.row_size = size
      s_a.column_size = size
      s_b = SparseMatrix.rows(rows_b)
      s_b.row_size = size
      s_b.column_size = size
      a = s_a.to_m
      b = s_b.to_m

      m_start = Time.now
      c = a * b
      m_end = Time.now

      sm_start = Time.now
      s_c = s_a * s_b
      sm_end = Time.now

      matrix_time += (m_end - m_start)
      sparse_matrix_time += (sm_end - sm_start)
    end

    results[size][sparsity][:matrix] = matrix_time / num_runs
    results[size][sparsity][:sparse_matrix] = sparse_matrix_time / num_runs
    m = results[size][sparsity][:matrix]
    sm = results[size][sparsity][:sparse_matrix]
    puts "#{size}x#{size} (#{sparsity}) : m => #{sprintf("%.4f",m)}s / sm => #{sprintf("%.4f",sm)}s => #{sprintf("%.2f", m / sm)}x"
  end
end

# results.keys.sort.reverse.each do |size|
#   results[size].keys.sort.reverse.each do |sparsity|
#     m = results[size][sparsity][:matrix]
#     sm = results[size][sparsity][:sparse_matrix]
#     puts "#{size}x#{size} (#{sparsity}) : m => #{sprintf("%.4f",m)}s / sm => #{sprintf("%.4f",sm)}s => #{sprintf("%.2f", m / sm)}x"
#   end
# end