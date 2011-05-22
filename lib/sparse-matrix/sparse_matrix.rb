require 'sparse-matrix/conversion_helper'
require 'sparse-matrix/coercion_helper'

class SparseMatrix < Matrix
  include ExceptionForMatrix
  include Enumerable
  include SM::CoercionHelper
  extend SM::ConversionHelper

  # instance creations
  private_class_method :new
  attr_reader :rows
  protected :rows

  #
  # Creates a sparse matrix where each argument is a row.
  #   SparseMatrix[ [25, 93], [-1, 66] ]
  #      =>  25 93
  #          -1 66
  #
  def SparseMatrix.[](*rows)
    SparseMatrix.rows(rows, false)
  end

  #
  # Creates a sparse matrix where +rows+ is an array or hash of arrays or hashes, each of which is a row
  # of the sparse matrix.  If the optional argument +copy+ is false, use the given
  # arrays as the internal structure of the sparse matrix without copying, only applies if hashes are given.
  #   SparseMatrix.rows([[25, 93], [-1, 66]])
  #      =>  25 93
  #          -1 66
  #
  def SparseMatrix.rows(rows, copy = true)
    rows = convert_to_hash(rows, copy)
    num_rows = rows.length
    num_columns = 0
    rows.each_pair do |k,v|
      num_elems = v.length
      rows[k] = convert_to_hash(v, copy)
      num_rows = k + 1 if k + 1 > num_rows
      tmp_num_col = [num_elems, rows[k].keys.max + 1].max
      num_columns = tmp_num_col if tmp_num_col > num_columns
    end

    new rows, num_rows, num_columns
  end

  #
  # Creates a sparse matrix using +columns+ as an array of column vectors.
  #   SparseMatrix.columns([[25, 93], [-1, 66]])
  #      =>  25 -1
  #          93 66
  #
  def SparseMatrix.columns(columns)
    raise "NOT IMPLEMENTED"
    SparseMatrix.rows(columns, false).transpose
  end

  #
  # Creates a sparse matrix of size +row_size+ x +column_size+.
  # It fills the values by calling the given block,
  # passing the current row and column.
  # Returns an enumerator if no block is given.
  #
  #   m = SparseMatrix.build(2, 4) {|row, col| col - row }
  #     => SparseMatrix[[0, 1, 2, 3], [-1, 0, 1, 2]]
  #   m = SparseMatrix.build(3) { rand }
  #     => a 3x3 sparse matrix with random elements
  #
  def SparseMatrix.build(row_size, column_size = row_size)
    raise "NOT IMPLEMENTED"
    row_size = CoercionHelper.coerce_to_int(row_size)
    column_size = CoercionHelper.coerce_to_int(column_size)
    raise ArgumentError if row_size < 0 || column_size < 0
    return to_enum :build, row_size, column_size unless block_given?
    rows = Array.new(row_size) do |i|
      Array.new(column_size) do |j|
        yield i, j
      end
    end
    new rows, column_size
  end

  #
  # Creates a sparse matrix where the diagonal elements are composed of +values+.
  #   SparseMatrix.diagonal(9, 5, -3)
  #     =>  9  0  0
  #         0  5  0
  #         0  0 -3
  #
  def SparseMatrix.diagonal(*values)
    raise "NOT IMPLEMENTED"
    size = values.size
    rows = Array.new(size) {|j|
      row = Array.new(size, 0)
      row[j] = values[j]
      row
    }
    new rows
  end

  #
  # Creates an +n+ by +n+ diagonal matrix where each diagonal element is
  # +value+.
  #   SparseMatrix.scalar(2, 5)
  #     => 5 0
  #        0 5
  #
  def SparseMatrix.scalar(n, value)
    raise "NOT IMPLEMENTED"
    Matrix.diagonal(*Array.new(n, value))
  end

  #
  # Creates an +n+ by +n+ identity sparse matrix.
  #   SpraseMatrix.identity(2)
  #     => 1 0
  #        0 1
  #
  def SparseMatrix.identity(n)
    raise "NOT IMPLEMENTED"
    SparseMatrix.scalar(n, 1)
  end
  class << SparseMatrix
    alias unit identity
    alias I identity
  end

  #
  # Creates an +n+ by +n+ zero sparse matrix.
  #   SparseMatrix.zero(2)
  #     => 0 0
  #        0 0
  #
  def SparseMatrix.zero(n)
    raise "NOT IMPLEMENTED"
    SparseMatrix.scalar(n, 0)
  end

  #
  # Creates a single-row SPARSE matrix where the values of that row are as given in
  # +row+.
  #   SPARSEMatrix.row_vector([4,5,6])
  #     => 4 5 6
  #
  def Matrix.row_vector(row)
    raise "NOT IMPLEMENTED"
    row = convert_to_array(row)
    new [row]
  end

  #
  # Creates a single-column matrix where the values of that column are as given
  # in +column+.
  #   Matrix.column_vector([4,5,6])
  #     => 4
  #        5
  #        6
  #
  def Matrix.column_vector(column)
    raise "NOT IMPLEMENTED"
    column = convert_to_array(column)
    new [column].transpose, 1
  end

  #
  # Creates a empty matrix of +row_size+ x +column_size+.
  # At least one of +row_size+ or +column_size+ must be 0.
  #
  #   m = Matrix.empty(2, 0)
  #   m == Matrix[ [], [] ]
  #     => true
  #   n = Matrix.empty(0, 3)
  #   n == Matrix.columns([ [], [], [] ])
  #     => true
  #   m * n
  #     => Matrix[[0, 0, 0], [0, 0, 0]]
  #
  def Matrix.empty(row_size = 0, column_size = 0)
    raise "NOT IMPLEMENTED"
    Matrix.Raise ArgumentError, "One size must be 0" if column_size != 0 && row_size != 0
    Matrix.Raise ArgumentError, "Negative size" if column_size < 0 || row_size < 0

    new([[]]*row_size, column_size)
  end

  #
  # SparseMatrix.new is private; use SparseMatrix.rows, columns, [], etc... to create.
  #
  def initialize(rows, num_rows, num_columns)
    # No checking is done at this point. rows must be a Hash of Hashes.
    # column_size must be the maximum value of the key set, if there are any,
    # otherwise it *must* be specified and can be any integer >= 0
    @rows = rows
    @row_size = num_rows
    @column_size = num_columns
  end

  def new_matrix(rows, column_size = rows[0].size) # :nodoc:
    raise "NOT IMPLEMENTED"
    Matrix.send(:new, rows, column_size) # bypass privacy of Matrix.new
  end
  private :new_matrix

  #
  # Returns element (+i+,+j+) of the matrix.  That is: row +i+, column +j+.
  #
  def [](i, j)
    @rows.fetch(i){return nil}[j]
  end
  alias element []
  alias component []

  def []=(i, j, v)
    @rows[i][j] = v
  end
  alias set_element []=
  alias set_component []=
  private :[]=, :set_element, :set_component

  #
  # Returns the number of rows.
  #
  def row_size
    @row_size
  end

  def column_size
    @column_size
  end

  #
  # Returns the number of columns.
  #
  attr_reader :column_size

  #
  # Returns row vector number +i+ of the matrix as a Vector (starting at 0 like
  # an array).  When a block is given, the elements of that vector are iterated.
  #
  def row(i, &block) # :yield: e
    raise "NOT IMPLEMENTED"
    if block_given?
      @rows.fetch(i){return self}.each(&block)
      self
    else
      Vector.elements(@rows.fetch(i){return nil})
    end
  end

  #
  # Returns column vector number +j+ of the matrix as a Vector (starting at 0
  # like an array).  When a block is given, the elements of that vector are
  # iterated.
  #
  def column(j) # :yield: e
    raise "NOT IMPLEMENTED"
    if block_given?
      return self if j >= column_size || j < -column_size
      row_size.times do |i|
        yield @rows[i][j]
      end
      self
    else
      return nil if j >= column_size || j < -column_size
      col = Array.new(row_size) {|i|
        @rows[i][j]
      }
      Vector.elements(col, false)
    end
  end

end
