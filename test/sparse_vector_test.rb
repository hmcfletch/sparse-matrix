require File.expand_path( File.join( File.dirname( __FILE__ ), 'test_helper' ) )

# add somce accessor so we can check under the hood
class SparseVector
  def elems; @elements end
end

class TestSparseVector < Test::Unit::TestCase

  # CREATION

  def test_creation_array
    sv = SparseVector[1,0,2,3,0,0]
    assert_equal 6, sv.size
    assert_equal 3, sv.nnz
    assert_equal({ 0 => 1, 2 => 2, 3 => 3 }, sv.elems)
    assert_equal 0, sv.elems.default
  end

  def test_creation_elements
    sv = SparseVector.elements([0,3,6,2,0,0])
    assert_equal 6, sv.size
    assert_equal 3, sv.nnz
    assert_equal({ 1 => 3, 2 => 6, 3 => 2 }, sv.elems)
    assert_equal 0, sv.elems.default
  end

  def test_creation_hash
    sv = SparseVector.elements({ 2 => 3, 5 => 1, 6 => 7 })
    assert_equal 7, sv.size
    assert_equal 3, sv.nnz
    assert_equal({ 2 => 3, 5 => 1, 6 => 7 }, sv.elems)
    assert_equal 0, sv.elems.default
  end

  def test_creation_vector
    sv = SparseVector.elements(Vector[0,2,4,0,0,1,0,0])
    assert_equal 8, sv.size
    assert_equal 3, sv.nnz
    assert_equal({ 1 => 2, 2 => 4, 5 => 1 }, sv.elems)
    assert_equal 0, sv.elems.default
  end

  # ACCESS

  def test_access
    sv = SparseVector.elements([1,3,6,0,4,0])
    assert_equal 1, sv[0]
    assert_equal 3, sv[1]
    assert_equal 6, sv[2]
    assert_equal 0, sv[3]
    assert_equal 4, sv[4]
    assert_equal 0, sv[5]
    assert sv[6].nil?
    assert sv[10].nil?
    assert_equal 0, sv[-1]
    assert_equal 4, sv[-2]
    assert_equal 0, sv[-3]
    assert_equal 6, sv[-4]
    assert_equal 3, sv[-5]
    assert_equal 1, sv[-6]
    assert sv[-7].nil?
    assert sv[-10].nil?

    assert_equal sv[1], sv.element(1)
    assert_equal sv[1], sv.component(1)
  end

  # ENUMERATION

  def test_nz_indicies
    sv = SparseVector.elements([0,3,0,2,0,0])
    assert_equal [1,3], sv.nz_indicies
  end

  def test_each
    sv = SparseVector.elements([0,3,6,2,0,0])
    ret_array = []
    sv.each do |k|
      ret_array << k
    end

    assert_equal [0,3,6,2,0,0], ret_array
  end

  def test_each_nz
    sv = SparseVector.elements([0,3,6,2,0,0])
    ret_array = []
    sv.each_nz do |k|
      ret_array << k
    end

    assert_equal [3,6,2], ret_array
  end

  def test_each2
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0])
    ret_array = []
    sv1.each2(sv2) do |k,l|
      ret_array << [k,l]
    end

    assert_equal [[0,1],[3,0],[0,0],[2,2],[0,6],[0,0]], ret_array
  end

  def test_each2_raise_type
    sv = SparseVector.elements([0,3,0,2,0,0])
    ret_array = []
    assert_raise(TypeError) do
      sv.each2(3) do |k,l|
        ret_array << [k,l]
      end
    end
  end

  def test_each2_raise_dimension
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0,1])
    ret_array = []
    assert_raise(ExceptionForMatrix::ErrDimensionMismatch) do
      sv1.each2(sv2) do |k,l|
        ret_array << [k,l]
      end
    end
  end

  def test_each2_nz
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0])
    ret_array = []
    sv1.each2_nz(sv2) do |k,l|
      ret_array << [k,l]
    end

    assert_equal [[0,1],[3,0],[2,2],[0,6]], ret_array
  end

  def test_each2_nz_raise_type
    sv = SparseVector.elements([0,3,0,2,0,0])
    ret_array = []
    assert_raise(TypeError) do
      sv.each2_nz(3) do |k,l|
        ret_array << [k,l]
      end
    end
  end

  def test_each2_nz_raise_dimension
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0,1])
    ret_array = []
    assert_raise(ExceptionForMatrix::ErrDimensionMismatch) do
      sv1.each2_nz(sv2) do |k,l|
        ret_array << [k,l]
      end
    end
  end

  def test_collect2
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0])
    ret_array = sv1.collect2(sv2) do |k,l|
      k != 0 || l != 0
    end

    assert_equal [true,true,false,true,true,false], ret_array
  end

  def test_collect2_raise_type
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    assert_raise(TypeError) do
      ret_array = sv1.collect2(3) do |k,l|
        k != 0 || l != 0
      end
    end
  end

  def test_collect2_raise_dimension
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0,1])
    assert_raise(ExceptionForMatrix::ErrDimensionMismatch) do
      ret_array = sv1.collect2(sv2) do |k,l|
        k != 0 || l != 0
      end
    end
  end

  def test_collect2_nz
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0])
    ret_array = sv1.collect2_nz(sv2) do |k,l|
      k != 0 || l != 0
    end

    assert_equal [true,true,nil,true,true,nil], ret_array
  end

  def test_collect
    sv = SparseVector.elements([0,3,0,2,0,0])
    ret_sv = sv.collect { |v| v * 2 }

    assert_equal SparseVector.elements([0,6,0,4,0,0]), ret_sv
  end

  def test_map2
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0])
    ret_sv = sv1.map2(sv2) do |k,l|
      (k * 2) + l + 3
    end

    assert_equal SparseVector[4,9,3,9,9,3], ret_sv
  end

  def test_map2_nz
    sv1 = SparseVector.elements([0,3,0,2,0,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0])
    ret_sv = sv1.map2_nz(sv2) do |k,l|
      (k * 2) + l + 3
    end

    assert_equal SparseVector[4,9,0,9,9,0], ret_sv
  end

  # COMPARING

  def test_double_eq
  end

  def test_eql?
  end

  def test_clone
  end

  # ARITHMETIC

  # +

  def test_addition_sparse_vector
    sv1 = SparseVector.elements([0,3,0,2,0,0,3,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0,5,0])

    assert_equal SparseVector[1,3,0,4,6,0,8,0], (sv1 + sv2)
  end

  def test_addition_vector
    sv = SparseVector.elements([0,3,0,2,0,0,3,0])
    v  = Vector.elements([1,0,0,2,6,0,5,0])

    assert_equal SparseVector[1,3,0,4,6,0,8,0], (sv + v)
  end

  def test_addition_sparse_matrix
  end

  def test_addition_matrix
  end

  # -

  def test_subtraction_sparse_vector
    sv1 = SparseVector.elements([0,3,0,2,0,0,3,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0,5,0])

    assert_equal SparseVector[-1,3,0,0,-6,0,-2,0], (sv1 - sv2)
  end

  def test_subtraction_vector
    sv = SparseVector.elements([0,3,0,2,0,0,3,0])
    v  = Vector.elements([1,0,0,2,6,0,5,0])

    assert_equal SparseVector[-1,3,0,0,-6,0,-2,0], (sv - v)
  end

  def test_subtraction_sparse_matrix
  end

  def test_subtraction_matrix
  end

  # *

  def test_multiplication_numeric
    sv = SparseVector.elements([0,3,0,2,0,0,3,0])

    assert_equal SparseVector[0,9,0,6,0,0,9,0], (sv * 3)
  end

  def test_multiplication_sparse_matrix
  end

  def test_multiplication_matrix
  end

  def test_multiplication_sparse_vector
  end

  def test_multiplication_vector
  end

  # /

  def test_division_numeric
    sv = SparseVector.elements([0,8,0,2,0,0,6,0])

    assert_equal SparseVector[0,4,0,1,0,0,3,0], (sv / 2)
  end

  def test_division_sparse_matrix
  end

  def test_division_matrix
  end

  # VECTOR FUNCTIONS

  def test_inner_product
    sv1 = SparseVector.elements([0,3,0,2,0,0,3,0])
    sv2 = SparseVector.elements([1,0,0,2,6,0,5,0])

    assert_equal 19, sv1.inner_product(sv2)
  end

  def test_r
    sv = SparseVector.elements([0,3,0,2,0,0,3,0])

    assert_equal Math.sqrt(22), sv.r
  end

  # CONVERTING

  def test_covector
  end

  def test_to_a
    sv = SparseVector.elements([0,3,0,2,0,0,3,0])

    assert_equal [0,3,0,2,0,0,3,0], sv.to_a
  end

  def test_to_v
    sv = SparseVector.elements([0,3,0,2,0,0,3,0])

    assert_equal Vector[0,3,0,2,0,0,3,0], sv.to_v
  end

  def test_elements_to_f
  end

  def test_elements_to_i
  end

  def test_elements_to_r
  end

end