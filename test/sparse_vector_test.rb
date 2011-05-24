# require 'test_helper'
require File.expand_path( File.join( File.dirname( __FILE__ ), 'test_helper' ) )

# add somce accessor so we can check under the hood
class SparseVector
  def elems; @elements end
end

class SparseMatrix
  def elems; @rows end
end

class TestCreation < Test::Unit::TestCase

  def setup
    # just in case
  end

  def test_sv_creation_array
    sv1 = SparseVector[1,0,2,3,0,0]
    assert sv1.size == 6
    assert sv1.elems == { 0 => 1, 2 => 2, 3 => 3 }
    assert sv1.elems.default == 0
  end

  def test_sv_creation_elements
    sv1 = SparseVector.elements([0,3,6,2,0,0])
    assert sv1.size == 6
    assert sv1.elems == { 1 => 3, 2 => 6, 3 => 2 }
    assert sv1.elems.default == 0

    sv2 = SparseVector.elements({ 2 => 3, 5 => 1, 6 => 7 })
    assert sv2.size == 7
    assert sv2.elems == { 2 => 3, 5 => 1, 6 => 7 }
    assert sv2.elems.default == 0

    sv3 = SparseVector.elements(Vector[0,2,4,0,0,1,0,0])
    assert sv3.size == 8
    assert sv3.elems == { 1 => 2, 2 => 4, 5 => 1 }
    assert sv3.elems.default == 0
  end

  def test_sm_creation_array
  end

  def test_sm_creation_rows_and_columns
  end

end