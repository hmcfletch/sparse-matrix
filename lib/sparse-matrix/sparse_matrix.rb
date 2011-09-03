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
      new ({ 0 => convert_to_hash(row) })
    else
      new ({ 0 => convert_to_hash(row) }), 1, row.size
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
    return nil if i >= row_size || j >= column_size
    @rows.fetch(i){ return 0 }[j]
  end
  alias element []
  alias component []

  def row_data; @rows end

  def []=(i, j, v)
    @rows[i][j] = v
  end
  alias set_element []=
  alias set_component []=
  private :[]=, :set_element, :set_component

  #
  # Returns the number of rows.
  #
  def row_size; @row_size end
  def row_size=(val); @row_size = val end

  #
  # Returns the number of columns.
  #
  def column_size; @column_size end
  def column_size=(val); @column_size = val end

  def nnz
    @rows.values.inject(0) { |m,v| m + v.size }
  end

  #
  # Returns sparse row vector number +i+ of the matrix as a Vector (starting at 0 like
  # an array).  When a block is given, the elements of that vector are iterated.
  #
  def row(i, &block) # :yield: e
    return nil if i >= row_size
    i = i < 0 ? row_size + i : i
    if block_given?
      @rows.fetch(i){ return self }
      column_size.times do |j|
        yield @rows[i][j]
      end
      self
    else
      SparseVector.elements(@rows.fetch(i){ Array.new(column_size,0) }, false, column_size)
    end
  end

  def row?(i)
    return !@rows[i].empty?
  end

  def column(i, &block) # :yield: e
    raise "NOT IMPLEMENTED"
    return nil if i >= row_size
    i = i < 0 ? row_size + i : i
    if block_given?
      @rows.fetch(i){ return self }
      column_size.times do |j|
        yield @rows[i][j]
      end
      self
    else
      SparseVector.elements(@rows.fetch(i){ Array.new(column_size,0) }, false, column_size)
    end
  end

  def column?(i)
    @rows.values.each do |row|
      return true if row.has_key?(i)
    end
  end

  private :row?

  #
  # Returns sparse row vector number +i+ of the matrix as a Vector (starting at 0 like
  # an array).  When a block is given, the non-zero elements of that vector are iterated.
  #
  def row_nz(i, &block) # :yield: e
    return nil if i >= row_size
    i = i < 0 ? row_size + i : i
    if block_given?
      @rows.fetch(i){ return self }
      @rows[i].keys.sort.each do |j|
        yield @rows[i][j]
      end
      self
    else
      SparseVector.elements(@rows.fetch(i){ Array.new(column_size,0) }, false, column_size)
    end
  end

  #
  # Returns sparse column vector number +j+ of the matrix as a SparseVector (starting at 0
  # like an array).  When a block is given, the elements of that vector are iterated.
  #
  def column(j) # :yield: e
    return nil if j >= column_size
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
      SparseVector.elements(col, false, row_size)
    end
  end

  #
  # Returns sparse column vector number +j+ of the matrix as a SparseVector (starting at 0
  # like an array).  When a block is given, the non-zero elements of that vector are iterated.
  #
  def column_nz(j) # :yield: e
    return nil if j >= column_size
    j = j < 0 ? column_size + j : j
    if block_given?
      return self if j >= column_size
      row_size.times do |i|
        next unless @rows.has_key?(i) && @rows[i].has_key?(j)
        yield @rows[i][j]
      end
      self
    else
      return nil if j >= column_size
      col = Array.new(row_size) { |i|
        @rows[i][j]
      }
      SparseVector.elements(col, false, row_size)
    end
  end

  #
  # Returns a sparse matrix that is the result of iteration of the given block over all
  # elements of the matrix.
  #   SparseMatrix[ [1,2], [3,4] ].collect { |e| e**2 }
  #     => 1  4
  #        9 16
  #
  def collect(&block) # :yield: e
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:collect) unless block_given?
    rows = {}
    row_size.times do |i|
      rows[i] = {}
      column_size.times do |j|
        k = yield self[i,j]
        rows[i][j] = k unless k == 0 || k.nil?
      end
    end
    new_matrix rows, row_size, column_size
  end
  alias map collect

  #
  # Returns a sparse matrix that is the result of iteration of the given block over all
  # non-zero elements of the matrix.
  #   SparseMatrix[ [1,2], [3,4] ].collect_nz { |e| e**2 }
  #     => 1  4
  #        9 16
  #
  def collect_nz(&block) # :yield: e
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:collect_nz) unless block_given?
    rows = {}
    @rows.keys.sort.each do |i|
      rows[i] = {}
      @rows[i].keys.sort.each do |j|
        k = yield self[i,j]
        rows[i][j] = k unless k == 0 || k.nil?
      end
    end
    new_matrix rows, row_size, column_size
  end
  alias map_nz collect_nz

  #
  # Yields all elements of the sparse matrix, starting with those of the first row,
  # or returns an Enumerator is no block given
  #   SparseMatrix[ [1,2], [3,4] ].each { |e| puts e }
  #     # => prints the numbers 1 to 4
  #
  def each(&block) # :yield: e
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:each) unless block_given?
    row_size.times do |i|
      column_size.times do |j|
        yield self[i,j]
      end
    end
    self
  end

  #
  # Yields all non-zero elements of the sparse matrix, starting with those of the first row,
  # or returns an Enumerator is no block given
  #   SparseMatrix[ [1,2], [3,4] ].each { |e| puts e }
  #     # => prints the numbers 1 to 4
  #
  def each_nz(&block) # :yield: e
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:each) unless block_given?
    @rows.keys.sort.each do |i|
      @rows[i].keys.sort.each do |j|
        yield self[i,j]
      end
    end
    self
  end

  #
  # Yields all elements of the sparse matrix, starting with those of the first row,
  # along with the row index and column index,
  # or returns an Enumerator is no block given
  #   SparseMatrix[ [1,0,2], [3,0,0], [0,0,4] ].each_with_index do |e, row, col|
  #     puts "#{e} at #{row}, #{col}"
  #   end
  #     # => 1 at 0, 0
  #     # => 0 at 0, 1
  #     # => 2 at 0, 2
  #     # => 3 at 1, 0
  #     # => 0 at 1, 1
  #     # => 0 at 1, 2
  #     # => 0 at 2, 0
  #     # => 0 at 2, 1
  #     # => 4 at 2, 2
  #
  def each_with_index(&block) # :yield: e, row, column
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:each) unless block_given?
    row_size.times do |i|
      column_size.times do |j|
        yield self[i,j], i, j
      end
    end
    self
  end

  #
  # Yields all non-zero elements of the sparse matrix, starting with those of the first row,
  # along with the row index and column index,
  # or returns an Enumerator is no block given
  #   SparseMatrix[ [1,0,2], [3,0,0], [0,0,4] ].each_with_index do |e, row, col|
  #     puts "#{e} at #{row}, #{col}"
  #   end
  #     # => 1 at 0, 0
  #     # => 2 at 0, 2
  #     # => 3 at 1, 0
  #     # => 4 at 2, 2
  #
  def each_with_index_nz(&block) # :yield: e, row, column
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:each) unless block_given?
    @rows.keys.sort.each do |i|
      @rows[i].keys.sort.each do |j|
        yield self[i,j], i, j
      end
    end
    self
  end

  #
  # Returns a section of the matrix.  The parameters are either:
  # *  start_row, nrows, start_col, ncols; OR
  # *  row_range, col_range
  #
  #   Matrix.diagonal(9, 5, -3).minor(0..1, 0..2)
  #     => 9 0 0
  #        0 5 0
  #
  # Like Array#[], negative indices count backward from the end of the
  # row or column (-1 is the last element). Returns nil if the starting
  # row or column is greater than row_size or column_size respectively.
  #
  def minor(*param)
    raise "NOT IMPLEMENTED"
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
    new_matrix @rows.map(&:dup), row_size, column_size
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

  #
  # Matrix multiplication.
  #   Matrix[[2,4], [6,8]] * Matrix.identity(2)
  #     => 2 4
  #        6 8
  #
  def *(m) # m is matrix or vector or number
    case(m)
    when Numeric
      rows = {}
      @rows.keys.each do |i|
        rows[i] = {}
        @rows[i].keys.each { |j| rows[i][j] = @rows[i][j] * m }
      end
      return new_matrix rows, row_size, column_size
    when SparseVector
      m = SparseMatrix.column_vector(m)
      r = self * m
      return r.column(0)
    when SparseMatrix
      SparseMatrix.Raise ErrDimensionMismatch if column_size != m.row_size

      c = {}
      row_size.times do |i|
        c[i] = {}
        m.column_size.times do |j|
          c_ij = 0
          @rows[i].each_pair do |k,v|
            c_ij += v * m[k,j]
          end
          c[i][j] = c_ij unless c_ij == 0
        end
      end

      return new_matrix c, row_size, m.column_size
    else
      raise "NOT IMPLEMENTED"
      # return apply_through_coercion(m, __method__)
    end
  end

  #
  # Matrix addition.
  #   Matrix.scalar(2,5) + Matrix[[1,0], [-4,7]]
  #     =>  6  0
  #        -4 12
  #
  def +(m)
    case m
    when Numeric
      SparseMatrix.Raise ErrOperationNotDefined, "+", self.class, m.class
    when Vector
      m = SparseMatrix.column_vector(m)
    when Matrix
    else
      return apply_through_coercion(m, __method__)
    end

    SparseMatrix.Raise ErrDimensionMismatch unless row_size == m.row_size and column_size == m.column_size

    # rows = Array.new(row_size) {|i|
    #   Array.new(column_size) {|j|
    #     self[i, j] + m[i, j]
    #   }
    # }

    rows = {}
    (row_data.keys + m.row_data.keys).uniq.each do |i|
      (row_data[i].keys + m.row_data[i].keys).uniq.each do |j|
        rows[i] ||= {}
        val = row_data[i][j] + m.row_data[i][j]
        rows[i][j] = val unless val == 0
      end
    end

    new_matrix rows, row_size, column_size
  end

  #
  # Matrix subtraction.
  #   Matrix[[1,5], [4,2]] - Matrix[[9,3], [-4,1]]
  #     => -8  2
  #         8  1
  #
  def -(m)
    case m
    when Numeric
      SparseMatrix.Raise ErrOperationNotDefined, "-", self.class, m.class
    when Vector
      m = SparseMatrix.column_vector(m)
    when Matrix
    else
      return apply_through_coercion(m, __method__)
    end

    SparseMatrix.Raise ErrDimensionMismatch unless row_size == m.row_size and column_size == m.column_size

    rows = {}
    (row_data.keys + m.row_data.keys).uniq.each do |i|
      (row_data[i].keys + m.row_data[i].keys).uniq.each do |j|
        rows[i] ||= {}
        val = row_data[i][j] - m.row_data[i][j]
        rows[i][j] = val unless val == 0
      end
    end

    new_matrix rows, row_size, column_size
  end

  #
  # Matrix division (multiplication by the inverse).
  #   Matrix[[7,6], [3,9]] / Matrix[[2,9], [3,1]]
  #     => -7  1
  #        -3 -6
  #
  def /(other)
    raise "NOT IMPLEMENTED"
  end

  #
  # Returns the inverse of the matrix.
  #   Matrix[[-1, -1], [0, -1]].inverse
  #     => -1  1
  #         0 -1
  #
  def inverse
    raise "NOT IMPLEMENTED"
  end

  def inverse_from(src) # :nodoc:
    raise "NOT IMPLEMENTED"
  end
  private :inverse_from

  #
  # Matrix exponentiation.  Currently implemented for integer powers only.
  # Equivalent to multiplying the matrix by itself N times.
  #   Matrix[[7,6], [3,9]] ** 2
  #     => 67 96
  #        48 99
  #
  def ** (other)
    raise "NOT IMPLEMENTED"
  end

  #--
  # MATRIX FUNCTIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns the determinant of the matrix.
  #
  # Beware that using Float values can yield erroneous results
  # because of their lack of precision.
  # Consider using exact types like Rational or BigDecimal instead.
  #
  #   Matrix[[7,6], [3,9]].determinant
  #     => 45
  #
  def determinant
    raise "NOT IMPLEMENTED"
  end
  alias_method :det, :determinant

  #
  # Private. Use Matrix#determinant
  #
  # Returns the determinant of the matrix, using
  # Bareiss' multistep integer-preserving gaussian elimination.
  # It has the same computational cost order O(n^3) as standard Gaussian elimination.
  # Intermediate results are fraction free and of lower complexity.
  # A matrix of Integers will have thus intermediate results that are also Integers,
  # with smaller bignums (if any), while a matrix of Float will usually have
  # intermediate results with better precision.
  #
  def determinant_bareiss
    raise "NOT IMPLEMENTED"
  end
  private :determinant_bareiss

  #
  # deprecated; use Matrix#determinant
  #
  def determinant_e
    raise "NOT IMPLEMENTED"
    warn "#{caller(1)[0]}: warning: Matrix#determinant_e is deprecated; use #determinant"
    rank
  end
  alias det_e determinant_e

  #
  # Returns the rank of the matrix.
  # Beware that using Float values can yield erroneous results
  # because of their lack of precision.
  # Consider using exact types like Rational or BigDecimal instead.
  #
  #   Matrix[[7,6], [3,9]].rank
  #     => 2
  #
  def rank
    raise "NOT IMPLEMENTED"
  end

  #
  # deprecated; use Matrix#rank
  #
  def rank_e
    raise "NOT IMPLEMENTED"
    warn "#{caller(1)[0]}: warning: Matrix#rank_e is deprecated; use #rank"
    rank
  end

  #
  # Returns the trace (sum of diagonal elements) of the matrix.
  #   Matrix[[7,6], [3,9]].trace
  #     => 16
  #
  def trace
    raise "NOT IMPLEMENTED"
    Matrix.Raise ErrDimensionMismatch unless square?
    (0...column_size).inject(0) do |tr, i|
      tr + @rows[i][i]
    end
  end
  alias tr trace


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

  def to_m
    rows = Array.new(row_size) do |i|
      r = Array.new(column_size,0)
      v = row(i)
      v.nz_indicies.each { |j| r[j] = v[j] } unless v.nil?
      r
    end
    Matrix.rows(rows)
  end

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
      "SparseMatrix#{@rows.inspect}, [#{row_size},#{column_size}]"
    end
  end

end
