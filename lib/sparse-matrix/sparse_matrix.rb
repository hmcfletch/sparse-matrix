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

      tmp_num_col = [num_elems, rows[k].empty? ? 0 : rows[k].keys.max + 1].max
      num_columns = tmp_num_col if tmp_num_col > num_columns
      # remove the row if it is empty
      rows.delete(k) if rows[k].empty?
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
    row_size = CoercionHelper.coerce_to_int(row_size)
    column_size = CoercionHelper.coerce_to_int(column_size)
    raise ArgumentError if row_size < 0 || column_size < 0
    return to_enum :build, row_size, column_size unless block_given?
    rows = {}
    row_size.times do |i|
      column_size.times do |j|
        rows[i] ||= {}
        val = yield i, j
        rows[i][j] = val unless val == 0
      end
    end
    new rows, row_size, column_size
  end

  #
  # Creates a sparse matrix where the diagonal elements are composed of +values+.
  #   SparseMatrix.diagonal(9, 5, -3)
  #     =>  9  0  0
  #         0  5  0
  #         0  0 -3
  #
  def SparseMatrix.diagonal(*values)
    size = values.size
    rows = {}
    size.times do |i|
      rows[i] = { i => values[i] } unless values[i] == 0
    end
    new rows, size, size
  end

  #
  # Creates an +n+ by +n+ diagonal matrix where each diagonal element is
  # +value+.
  #   SparseMatrix.scalar(2, 5)
  #     => 5 0
  #        0 5
  #
  def SparseMatrix.scalar(n, value)
    SparseMatrix.diagonal(*Array.new(n, value))
  end

  #
  # Creates an +n+ by +n+ identity sparse matrix.
  #   SpraseMatrix.identity(2)
  #     => 1 0
  #        0 1
  #
  def SparseMatrix.identity(n)
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
    SparseMatrix.scalar(n, 0)
  end

  #
  # Creates a single-row sparse matrix where the values of that row are as given in
  # +row+.
  #   SparseMatrix.row_vector([4,5,6])
  #     => 4 5 6
  #
  def SparseMatrix.row_vector(row)
    if row.is_a?(Hash)
      new convert_to_hash(row)
    else
      new convert_to_hash(row), 1, row.size
    end
  end

  #
  # Creates a single-column sparse matrix where the values of that column are as given
  # in +column+.
  #   SparseMatrix.column_vector([4,5,6])
  #     => 4
  #        5
  #        6
  #
  def SparseMatrix.column_vector(column)
    if column.is_a?(Hash)
      new ({ 0 => convert_to_hash(column) }).transpose
    else
      new ({ 0 => convert_to_hash(column) }).transpose, column.size, 1
    end
  end

  #
  # Creates a empty sparse matrix of +row_size+ x +column_size+.
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
  def SparseMatrix.empty(row_size = 0, column_size = 0)
    SparseMatrix.Raise ArgumentError, "One size must be 0" if column_size != 0 && row_size != 0
    SparseMatrix.Raise ArgumentError, "Negative size" if column_size < 0 || row_size < 0

    new({}, row_size, column_size)
  end

  #
  # SparseMatrix.new is private; use SparseMatrix.rows, columns, [], etc... to create.
  #
  def initialize(rows, num_rows=nil, num_columns=nil)
    # No checking is done at this point. rows must be a Hash of Hashes.
    # column_size must be the maximum value of the key set, if there are any,
    # otherwise it *must* be specified and can be any integer >= 0
    @rows = rows

    # determine size if not given
    if num_rows.nil? || num_columns.nil?
      if rows.is_a?(Hash)
        num_rows = rows.keys.max + 1 if num_rows.nil?
        num_columns = rows.values.collect { |c| c.keys.max }.max + 1 if num_columns.nil?
      elsif rows.is_a?(Array)
        num_rows = rows.size if num_rows.nil?
        num_columns = rows[0].size if num_columns.nil?
      end
    end
    @row_size = num_rows
    @column_size = num_columns

    # set defaults for the hashes
    @rows.default = Hash.new(0)
    @rows.keys.each do |k|
      @rows[k].default = 0
    end
  end

  def new_matrix(rows, row_size = nil, column_size = nil) # :nodoc:
    SparseMatrix.send(:new, rows, row_size, column_size) # bypass privacy of Matrix.new
  end
  private :new_matrix

  #
  # Returns element (+i+,+j+) of the matrix.  That is: row +i+, column +j+.
  #
  def [](i, j)
    @rows.fetch(i){ return nil }[j]
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

  def nnz
    @rows.values.inject(0) { |m,v| m + v.size }
  end

  #
  # Returns sparse row vector number +i+ of the matrix as a Vector (starting at 0 like
  # an array).  When a block is given, the elements of that vector are iterated.
  #
  def row(i, &block) # :yield: e
    i = i < 0 ? row_size - i : i
    if block_given?
      @rows.fetch(i){return self}
      column_size.times do |j|
        yield @rows[i][j]
      end
      self
    else
      SparseVector.elements(@rows.fetch(i){return nil})
    end
  end

  #
  # Returns sparse row vector number +i+ of the matrix as a Vector (starting at 0 like
  # an array).  When a block is given, the non-zero elements of that vector are iterated.
  #
  def row_nz(i, &block) # :yield: e
    i = i < 0 ? row_size + i : i
    if block_given?
      @rows.fetch(i){return self}
      @rows[i].keys.sort do |j|
        yield @rows[i][j]
      end
      self
    else
      SparseVector.elements(@rows.fetch(i){return nil})
    end
  end

  #
  # Returns sparse column vector number +j+ of the matrix as a SparseVector (starting at 0
  # like an array).  When a block is given, the elements of that vector are iterated.
  #
  def column(j) # :yield: e
    j = j < 0 ? column_size + j : j
    if block_given?
      return self if j >= column_size
      row_size.times do |i|
        yield @rows[i][j]
      end
      self
    else
      return nil if j >= column_size
      col = Array.new(row_size) { |i|
        @rows[i][j]
      }
      SparseVector.elements(col, false)
    end
  end

  #
  # Returns sparse column vector number +j+ of the matrix as a SparseVector (starting at 0
  # like an array).  When a block is given, the non-zero elements of that vector are iterated.
  #
  def column_nz(j) # :yield: e
    j = j < 0 ? column_size + j : j
    if block_given?
      return self if j >= column_size
      row_size.times do |i|
        yield @rows[i][j]
      end
      self
    else
      return nil if j >= column_size
      col = Array.new(row_size) { |i|
        @rows[i][j]
      }
      SparseVector.elements(col, false)
    end
  end

  #--
  # TESTING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns +true+ if this is an empty matrix, i.e. if the number of rows
  # or the number of columns is 0.
  #
  def empty?
    column_size == 0 || row_size == 0
  end

  #
  # Returns +true+ if all entries of the matrix are real.
  #
  def real?
    all?(&:real?)
  end

  #
  # Returns +true+ if this is a regular (i.e. non-singular) matrix.
  #
  def regular?
    not singular?
  end

  #
  # Returns +true+ is this is a singular matrix.
  #
  def singular?
    raise "NOT IMPLEMENTED"
    determinant == 0
  end

  #
  # Returns +true+ is this is a square matrix.
  #
  def square?
    column_size == row_size
  end

  #--
  # OBJECT METHODS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns +true+ if and only if the two matrices contain equal elements.
  #
  def ==(other)
    return false unless SparseMatrix === other &&
                        column_size == other.column_size &&
                        row_size == other.row_size # necessary for empty matrices
    rows == other.rows
  end

  def eql?(other)
    return false unless Matrix === other &&
                        column_size == other.column_size &&
                        row_size == other.row_size # necessary for empty matrices
    rows.eql? other.rows
  end

  #
  # Returns a clone of the matrix, so that the contents of each do not reference
  # identical objects.
  # There should be no good reason to do this since Matrices are immutable.
  #
  def clone
    raise "NOT IMPLEMENTED"
    new_matrix @rows.map(&:dup), column_size
  end

  #
  # Returns a hash-code for the matrix.
  #
  def hash
    @rows.hash
  end

  #--
  # ARITHMETIC -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #--
  # MATRIX FUNCTIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns the transpose of the matrix.
  #   Matrix[[1,2], [3,4], [5,6]]
  #     => 1 2
  #        3 4
  #        5 6
  #   Matrix[[1,2], [3,4], [5,6]].transpose
  #     => 1 3 5
  #        2 4 6
  #
  def transpose
    return SparseMatrix.empty(column_size, 0) if row_size.zero?
    new_matrix @rows.transpose, column_size, row_size
  end
  alias t transpose

  #--
  # COMPLEX ARITHMETIC -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  #++

  #--
  # CONVERTING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #--
  # PRINTING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Overrides Object#to_s
  #
  def to_s
    if empty?
      "SparseMatrix.empty(#{row_size}, #{column_size})"
    else
      "SparseMatrix[" + @rows.collect{|row|
        "[" + row.collect{|e| e.to_s}.join(", ") + "]"
      }.join(", ")+"]"
    end
  end

  #
  # Overrides Object#inspect
  #
  def inspect
    if empty?
      "SparseMatrix.empty(#{row_size}, #{column_size})"
    else
      "SparseMatrix#{@rows.inspect}"
    end
  end

end
