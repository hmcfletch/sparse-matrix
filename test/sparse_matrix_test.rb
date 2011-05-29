require File.expand_path( File.join( File.dirname( __FILE__ ), 'test_helper' ) )

# add somce accessor so we can check under the hood
class SparseMatrix
  def elems; @rows end
end

class TestSparseMatrix < Test::Unit::TestCase

  def test_creation_array
    sm = SparseMatrix[[1,0,2],[3,0,0],[0,4,5]]
    assert sm.row_size == 3
    assert sm.column_size == 3
    assert sm.elems == { 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } }
    assert sm.elems.default == Hash.new(0)
    assert sm.elems[0].default == 0
    assert sm.elems[1].default == 0
    assert sm.elems[2].default == 0
    assert sm.nnz == 5
  end

  def test_creation_rows_array
    sm = SparseMatrix.rows([[1,0,2],[3,0,0],[0,4,5]])
    assert sm.row_size == 3
    assert sm.column_size == 3
    assert sm.elems == { 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } }
    assert sm.elems.default == Hash.new(0)
    assert sm.elems[0].default == 0
    assert sm.elems[1].default == 0
    assert sm.elems[2].default == 0
    assert sm.nnz == 5
  end

  def test_creation_rows_hash
    sm = SparseMatrix.rows({ 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } })
    assert sm.row_size == 3
    assert sm.column_size == 3
    assert sm.elems == { 0 => { 0 => 1, 2 => 2 }, 1 => { 0 => 3 }, 2 => { 1 => 4, 2 => 5 } }
    assert sm.elems.default == Hash.new(0)
    assert sm.elems[0].default == 0
    assert sm.elems[1].default == 0
    assert sm.elems[2].default == 0
    assert sm.nnz == 5
  end

  def test_creation_columns
    sm = SparseMatrix.columns([[1,0],[3,0],[0,4]])
    assert sm.row_size == 2
    assert sm.column_size == 3
    assert sm.elems == { 0 => { 0 => 1, 1 => 3 }, 1 => { 2 => 4 } }
    assert sm.elems.default == Hash.new(0)
    assert sm.elems[0].default == 0
    assert sm.elems[1].default == 0
    assert sm.nnz == 3
  end

  def test_creation_build
  end

  def test_creation_diagonal
    sm = SparseMatrix.diagonal(3,4,0,9,0)
    assert sm.row_size == 5
    assert sm.column_size == 5
    assert sm.elems == { 0 => { 0 => 3 }, 1 => { 1 => 4 }, 3 => { 3 => 9 } }
    assert sm.nnz == 3
  end

  def test_creation_scalar
    sm = SparseMatrix.scalar(3,4)
    assert sm.row_size == 3
    assert sm.column_size == 3
    assert sm.elems == { 0 => { 0 => 4 }, 1 => { 1 => 4 }, 2 => { 2 => 4 } }
    assert sm.nnz == 3
  end

  def test_creation_identity
    sm = SparseMatrix.identity(3)
    assert sm.row_size == 3
    assert sm.column_size == 3
    assert sm.elems == { 0 => { 0 => 1 }, 1 => { 1 => 1 }, 2 => { 2 => 1 } }
    assert sm.nnz == 3
  end

  def test_creation_zero
    sm = SparseMatrix.zero(3)
    assert sm.row_size == 3
    assert sm.column_size == 3
    assert sm.elems == {}
    assert sm.nnz == 0
  end

  def test_row_vector_array
    sm = SparseMatrix.row_vector([1,3,0,0,6])
    assert sm.row_size == 1
    assert sm.column_size == 5
    assert sm.elems == { 0 => { 0 => 1, 1 => 3, 4 => 6 } }
    assert sm.nnz == 3
  end

  def test_row_vector_hash
    sm = SparseMatrix.row_vector({ 0 => 1, 1 => 3, 4 => 6 })
    assert sm.row_size == 1
    assert sm.column_size == 5
    assert sm.elems == { 0 => { 0 => 1, 1 => 3, 4 => 6 } }
    assert sm.nnz == 3
  end

  def test_column_vector_array
    sm = SparseMatrix.column_vector([1,3,0,0,6])
    assert sm.row_size == 5
    assert sm.column_size == 1
    assert sm.elems == { 0 => { 0 => 1 }, 1 => { 0 => 3 }, 4 => { 0 => 6 } }
    assert sm.nnz == 3
  end

  def test_column_vector_hash
    sm = SparseMatrix.column_vector({ 0 => 1, 1 => 3, 4 => 6 })
    assert sm.row_size == 5
    assert sm.column_size == 1
    assert sm.elems == { 0 => { 0 => 1 }, 1 => { 0 => 3 }, 4 => { 0 => 6 } }
    assert sm.nnz == 3
  end

  def test_empty
    sm1 = SparseMatrix.empty(3,0)
    assert sm1.row_size == 3
    assert sm1.column_size == 0
    assert sm1.elems == {}
    assert sm1.nnz == 0

    sm2 = SparseMatrix.empty(0,4)
    assert sm2.row_size == 0
    assert sm2.column_size == 4
    assert sm2.elems == {}
    assert sm2.nnz == 0
  end

  def test_access
    sm = SparseMatrix[[1,0,2],[3,0,0],[0,4,5]]
    assert sm[0,0] == 1
    assert sm[0,1] == 0
    assert sm[0,2] == 2
    assert sm[1,0] == 3
    assert sm[1,1] == 0
    assert sm[1,2] == 0
    assert sm[2,0] == 0
    assert sm[2,1] == 4
    assert sm[2,2] == 5
    assert sm[3,3] == nil
  end

  def test_row_no_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert sm.row(0) == SparseVector[1,3,0]
    assert sm.row(2) == SparseVector[3,9,0]
    assert sm.row(-1) == SparseVector[0,4,0]
    assert sm.row(-3) == SparseVector[6,0,0]
  end

  def test_row_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.row(0) { |v| a += v }
    assert a == 4
    a = 0
    sm.row(1) { |v| a += 1 if v != 0 }
    assert a == 1
    a = 0
    sm.row(-2) { |v| a += 1 if v == 0 }
    assert a == 2
  end

  def test_row_nz_no_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert sm.row_nz(0) == SparseVector[1,3,0]
    assert sm.row_nz(2) == SparseVector[3,9,0]
    assert sm.row_nz(-1) == SparseVector[0,4,0]
    assert sm.row_nz(-3) == SparseVector[6,0,0]
  end

  def test_row_nz_block
    sm = SparseMatrix.rows([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.row_nz(0) { |v| a += 1 }
    assert a == 2
    a = 0
    sm.row_nz(1) { |v| a += 1 if v != 0 }
    assert a == 1
    a = 0
    sm.row_nz(-1) { |v| a += 1 if v == 0 }
    assert a == 0
  end

  def test_column_no_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert sm.column(0) == SparseVector[1,3,0]
    assert sm.column(2) == SparseVector[3,9,0]
    assert sm.column(-1) == SparseVector[0,4,0]
    assert sm.column(-3) == SparseVector[6,0,0]
  end

  def test_column_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.column(0) { |v| a += v }
    assert a == 4
    a = 0
    sm.column(1) { |v| a += 1 if v != 0 }
    assert a == 1
    a = 0
    sm.column(-2) { |v| a += 1 if v == 0 }
    assert a == 2
  end

  def test_column_nz_no_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0],[0,0,5],[6,0,0],[2,0,6],[0,4,0]])
    assert sm.column_nz(0) == SparseVector[1,3,0]
    assert sm.column_nz(2) == SparseVector[3,9,0]
    assert sm.column_nz(-1) == SparseVector[0,4,0]
    assert sm.column_nz(-3) == SparseVector[6,0,0]
  end

  def test_column_nz_block
    sm = SparseMatrix.columns([[1,3,0],[0,0,4],[3,9,0]])
    a = 0
    sm.column_nz(0) { |v| a += 1 }
    assert a == 2
    a = 0
    sm.column_nz(1) { |v| a += 1 if v != 0 }
    assert a == 1
    a = 0
    sm.column_nz(-1) { |v| a += 1 if v == 0 }
    assert a == 0
  end

  def test_collect
  end

  def test_each
  end

  def test_each_with_index
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
    sm1 = SparseMatrix.rows([[1,0],[3,0],[0,4]])
    assert sm1.row_size == 3
    assert sm1.column_size == 2
    smt = sm1.transpose
    assert smt.row_size == 2
    assert smt.column_size == 3
    assert smt == SparseMatrix.rows([[1,3,0],[0,0,4]])
  end

end