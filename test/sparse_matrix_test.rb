require File.expand_path( File.join( File.dirname( __FILE__ ), 'test_helper' ) )

# add somce accessor so we can check under the hood
class SparseMatrix
  def elems; @rows end
end

class TestSparseMatrix < Test::Unit::TestCase

  def setup
    # just in case
  end

  def test_creation_array
    assert_true
  end

end