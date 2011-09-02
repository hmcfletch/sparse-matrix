require File.expand_path( File.join( File.dirname( __FILE__ ), 'test_helper' ) )

class TestSparseMatrix < Test::Unit::TestCase

  def test_creation_array
    sm = SparseMatrix[[1,0,2],[3,0,0],[0,4,5]]
    assert_equal 3, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({ 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } }, sm.row_data)
    assert_equal Hash.new(0), sm.row_data.default
    assert_equal 0, sm.row_data[0].default
    assert_equal 0, sm.row_data[1].default
    assert_equal 0, sm.row_data[2].default
    assert_equal 5, sm.nnz
  end

  def test_creation_rows_array
    sm = SparseMatrix.rows([[1,0,2],[3,0,0],[0,4,5]])
    assert_equal 3, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({ 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } }, sm.row_data)
    assert_equal Hash.new(0), sm.row_data.default
    assert_equal 0, sm.row_data[0].default
    assert_equal 0, sm.row_data[1].default
    assert_equal 0, sm.row_data[2].default
    assert_equal 5, sm.nnz
  end

  def test_creation_columns_array
    sm = SparseMatrix.columns([[1,0,2],[3,0,0],[0,4,5]])
    assert_equal 3, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({ 0 => { 0 => 1, 1 => 3 }, 1 => { 2 => 4 }, 2 => { 0 => 2, 2 => 5 } }, sm.row_data)
    assert_equal Hash.new(0), sm.row_data.default
    assert_equal 0, sm.row_data[0].default
    assert_equal 0, sm.row_data[1].default
    assert_equal 0, sm.row_data[2].default
    assert_equal 5, sm.nnz
  end

  def test_creation_rows_hash
    sm = SparseMatrix.rows({ 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } })
    assert_equal 3, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({ 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } }, sm.row_data)
    assert_equal Hash.new(0), sm.row_data.default
    assert_equal 0, sm.row_data[0].default
    assert_equal 0, sm.row_data[1].default
    assert_equal 0, sm.row_data[2].default
    assert_equal 5, sm.nnz
  end

  def test_creation_columns
    sm = SparseMatrix.columns([[1,0],[3,0],[0,4]])
    assert_equal 2, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({ 0 => { 0 => 1, 1 => 3 }, 1 => { 2 => 4 } }, sm.row_data)
    assert_equal Hash.new(0), sm.row_data.default
    assert_equal 0, sm.row_data[0].default
    assert_equal 0, sm.row_data[1].default
    assert_equal 3, sm.nnz
  end

  def test_creation_build
  end

  def test_creation_diagonal
    sm = SparseMatrix.diagonal(3,4,0,9,0)
    assert_equal 5, sm.row_size
    assert_equal 5, sm.column_size
    assert_equal({ 0 => { 0 => 3 }, 1 => { 1 => 4 }, 3 => { 3 => 9 } }, sm.row_data)
    assert_equal 3, sm.nnz
  end

  def test_creation_scalar
    sm = SparseMatrix.scalar(3,4)
    assert_equal 3, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({ 0 => { 0 => 4 }, 1 => { 1 => 4 }, 2 => { 2 => 4 } }, sm.row_data)
    assert_equal 3, sm.nnz
  end

  def test_creation_identity
    sm = SparseMatrix.identity(3)
    assert_equal 3, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({ 0 => { 0 => 1 }, 1 => { 1 => 1 }, 2 => { 2 => 1 } }, sm.row_data)
    assert_equal 3, sm.nnz
  end

  def test_creation_zero
    sm = SparseMatrix.zero(3)
    assert_equal 3, sm.row_size
    assert_equal 3, sm.column_size
    assert_equal({}, sm.row_data)
    assert_equal 0, sm.nnz
  end

  def test_row_vector_array
    sm = SparseMatrix.row_vector([1,3,0,0,6])
    assert_equal 1, sm.row_size
    assert_equal 5, sm.column_size
    assert_equal({ 0 => { 0 => 1, 1 => 3, 4 => 6 } }, sm.row_data)
    assert_equal 3, sm.nnz
  end

  def test_row_vector_hash
    sm = SparseMatrix.row_vector({ 0 => 1, 1 => 3, 4 => 6 })
    assert_equal 1, sm.row_size
    assert_equal 5, sm.column_size
    assert_equal({ 0 => { 0 => 1, 1 => 3, 4 => 6 } }, sm.row_data)
    assert_equal 3, sm.nnz
  end

  def test_column_vector_array
    sm = SparseMatrix.column_vector([1,3,0,0,6])
    assert_equal 5, sm.row_size
    assert_equal 1, sm.column_size
    assert_equal({ 0 => { 0 => 1 }, 1 => { 0 => 3 }, 4 => { 0 => 6 } }, sm.row_data)
    assert_equal 3, sm.nnz
  end

  def test_column_vector_hash
    sm = SparseMatrix.column_vector({ 0 => 1, 1 => 3, 4 => 6 })
    assert_equal 5, sm.row_size
    assert_equal 1, sm.column_size
    assert_equal( { 0 => { 0 => 1 }, 1 => { 0 => 3 }, 4 => { 0 => 6 } }, sm.row_data)
    assert_equal 3, sm.nnz
  end

  def test_empty
    sm1 = SparseMatrix.empty(3,0)
    assert_equal 3, sm1.row_size
    assert_equal 0, sm1.column_size
    assert_equal({}, sm1.row_data)
    assert_equal 0, sm1.nnz

    sm2 = SparseMatrix.empty(0,4)
    assert_equal 0, sm2.row_size
    assert_equal 4, sm2.column_size
    assert_equal({}, sm2.row_data)
    assert_equal 0, sm2.nnz
  end

  def test_access
    sm = SparseMatrix[[1,0,2],[3,0,0],[0,4,5]]
    assert_equal 1, sm[0,0]
    assert_equal 0, sm[0,1]
    assert_equal 2, sm[0,2]
    assert_equal 3, sm[1,0]
    assert_equal 0, sm[1,1]
    assert_equal 0, sm[1,2]
    assert_equal 0, sm[2,0]
    assert_equal 4, sm[2,1]
    assert_equal 5, sm[2,2]
    assert_equal nil, sm[3,3]
  end

  def test_row_no_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert_equal SparseVector[1,3,0], sm.row(0)
    assert_equal SparseVector[3,9,0], sm.row(2)
    assert_equal SparseVector[0,4,0], sm.row(-1)
    assert_equal SparseVector[6,0,0], sm.row(-3)
  end

  def test_row_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.row(0) { |v| a += v }
    assert_equal 4, a
    a = 0
    sm.row(1) { |v| a += 1 if v != 0 }
    assert_equal 1, a
    a = 0
    sm.row(-2) { |v| a += 1 if v == 0 }
    assert_equal 2, a
  end

  def test_row_nz_no_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert_equal SparseVector[1,3,0], sm.row_nz(0)
    assert_equal SparseVector[3,9,0], sm.row_nz(2)
    assert_equal SparseVector[0,4,0], sm.row_nz(-1)
    assert_equal SparseVector[6,0,0], sm.row_nz(-3)
  end

  def test_row_nz_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.row_nz(0) { |v| a += 1 }
    assert_equal 2, a
    a = 0
    sm.row_nz(1) { |v| a += 1 if v != 0 }
    assert_equal 1, a
    a = 0
    sm.row_nz(-1) { |v| a += 1 if v == 0 }
    assert_equal 0, a
  end

  def test_column_no_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert_equal SparseVector[1,3,0], sm.column(0)
    assert_equal SparseVector[3,9,0], sm.column(2)
    assert_equal SparseVector[0,4,0], sm.column(-1)
    assert_equal SparseVector[6,0,0], sm.column(-3)
  end

  def test_column_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.column(0) { |v| a += v }
    assert_equal 4, a
    a = 0
    sm.column(1) { |v| a += 1 if v != 0 }
    assert_equal 1, a
    a = 0
    sm.column(-2) { |v| a += 1 if v == 0 }
    assert_equal 2, a
  end

  def test_column_nz_no_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert_equal SparseVector[1,3,0], sm.column_nz(0)
    assert_equal SparseVector[3,9,0], sm.column_nz(2)
    assert_equal SparseVector[0,4,0], sm.column_nz(-1)
    assert_equal SparseVector[6,0,0], sm.column_nz(-3)
  end

  def test_column_nz_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.column_nz(0) { |v| a += 1 }
    assert_equal 2, a
    a = 0
    sm.column_nz(1) { |v| a += 1 if v != 0 }
    assert_equal 1, a
    a = 0
    sm.column_nz(-1) { |v| a += 1 if v == 0 }
    assert_equal 0, a
  end

  def test_collect
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    smc = sm.collect { |v| v - 3 }
    assert_equal SparseMatrix.rows([[-2,0,-3],[-3,-3,1],[0,6,-3]]), smc
  end

  def test_collect_nz
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    smc = sm.collect_nz { |v| v - 3 }
    assert_equal SparseMatrix.rows([[-2,0,0],[0,0,1],[0,6,0]]), smc
  end

  def test_each
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    num_nz = 0
    num_z = 0
    sm.each do |v|
      num_nz += 1 if v != 0
      num_z  += 1 if v == 0
    end
    assert_equal 5, num_nz
    assert_equal 4, num_z
  end

  def test_each_nz
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    num_nz = 0
    num_z = 0
    sm.each_nz do |v|
      num_nz += 1 if v != 0
      num_z  += 1 if v == 0
    end
    assert_equal 5, num_nz
    assert_equal 0, num_z
  end

  def test_each_with_index
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    vals = []
    sm.each_with_index do |k,i,j|
      vals << [i,j,k]
    end
    assert_equal [0,0,1], vals[0]
    assert_equal [0,1,3], vals[1]
    assert_equal [0,2,0], vals[2]
    assert_equal [1,0,0], vals[3]
    assert_equal [1,1,0], vals[4]
    assert_equal [1,2,4], vals[5]
    assert_equal [2,0,3], vals[6]
    assert_equal [2,1,9], vals[7]
    assert_equal [2,2,0], vals[8]
  end

  def test_each_with_index_nz
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    vals = []
    sm.each_with_index_nz do |k,i,j|
      vals << [i,j,k]
    end
    assert_equal [0,0,1], vals[0]
    assert_equal [0,1,3], vals[1]
    assert_equal [1,2,4], vals[2]
    assert_equal [2,0,3], vals[3]
    assert_equal [2,1,9], vals[4]
  end

  def test_minor
  end

  def test_empty?
    sm1 = SparseMatrix.rows([])
    assert sm1.empty?
    sm2 = SparseMatrix.rows([[1,0,0],[3,0,0],[0,4,0]])
    assert !sm2.empty?
    sm3 = SparseMatrix.empty
    assert sm3.empty?
  end

  def test_real?
  end

  def test_regular?
  end

  def test_singular?
  end

  def test_square?
    sms = SparseMatrix.rows([[1,0,0],[3,0,0],[0,4,0]])
    assert sms.square?
    smr = SparseMatrix.rows([[1,0],[3,0],[0,4]])
    assert !smr.square?
  end

  def test_transpose
    sm = SparseMatrix.rows([[1,0],[3,0],[0,4]])
    assert_equal 3, sm.row_size
    assert_equal 2, sm.column_size
    smt = sm.transpose
    assert_equal 2, smt.row_size
    assert_equal 3, smt.column_size
    assert_equal SparseMatrix.rows([[1,3,0],[0,0,4]]), smt
  end

  def test_multiplication_numeric
    sm = SparseMatrix.rows([[1,0],[3,0],[0,4]])
    smn = sm * 2
    assert_equal SparseMatrix[[2,0],[6,0],[0,8]], smn
  end

  def test_multiplication_vector
  end

  def test_multiplication_matrix
    m1 = Matrix.rows([[2,0,0,6,0,0,0],[0,4,0,0,0,8,0],[0,0,5,0,7,0,9]])
    m2 = Matrix.rows([[0,2,0],[0,3,0],[4,0,0],[0,0,1],[8,0,0],[0,0,6],[3,0,0]])
    mr1 = m1 * m2
    mr2 = m2 * m1
    sm1 = SparseMatrix.rows([[2,0,0,6,0,0,0],[0,4,0,0,0,8,0],[0,0,5,0,7,0,9]])
    sm2 = SparseMatrix.rows([[0,2,0],[0,3,0],[4,0,0],[0,0,1],[8,0,0],[0,0,6],[3,0,0]])
    smr1 = sm1 * sm2
    smr2 = sm2 * sm1
    assert_equal mr1.to_sm, smr1
    assert_equal mr2.to_sm, smr2
  end

  def test_addition_numeric
    sm1 = SparseMatrix.rows([[2,0,0,6,0,0,0],[0,4,0,0,0,8,0],[0,0,5,0,7,0,9]])
    assert_raise(ExceptionForMatrix::ErrOperationNotDefined) do
      smr = sm1 + 2
    end
  end

  def test_addition_vector
  end

  def test_addition_matrix
    sm1 = SparseMatrix.rows([[2,0,0,6,0,0,0],[0,4,0,0,0,8,0],[0,0,5,0,7,0,9]])
    sm2 = SparseMatrix.rows([[2,3,0,0,2,0,0],[1,1,0,4,0,2,0],[0,3,5,0,0,0,-3]])
    smr = sm1 + sm2
    assert_equal SparseMatrix.rows([[4,3,0,6,2,0,0],[1,5,0,4,0,10,0],[0,3,10,0,7,0,6]]), smr
  end

  def test_subtraction_numeric
    sm1 = SparseMatrix.rows([[2,0,0,6,0,0,0],[0,4,0,0,0,8,0],[0,0,5,0,7,0,9]])
    assert_raise(ExceptionForMatrix::ErrOperationNotDefined) do
      smr = sm1 - 3
    end
  end

  def test_subtraction_vector
  end

  def test_subtraction_matrix
    sm1 = SparseMatrix.rows([[2,0,0,6,0,0,0],[0,4,0,0,0,8,0],[0,0,5,0,7,0,9]])
    sm2 = SparseMatrix.rows([[2,3,0,0,2,0,0],[1,1,0,4,0,2,0],[0,3,5,0,0,0,-3]])
    smr = sm2 - sm1
    assert_equal SparseMatrix.rows([[0,3,0,-6,2,0,0],[1,-3,0,4,0,-6,0],[0,3,0,0,-7,0,-12]]), smr
  end

end
