require 'sparse-matrix/conversion_helper'
require 'sparse-matrix/coercion_helper'

class SparseVector < Vector
  include ExceptionForMatrix
  include Enumerable
  include SM::CoercionHelper
  extend SM::ConversionHelper

  # instance creations
  private_class_method :new
  attr_reader :elements
  protected :elements

  #
  # Creates a SparseVector from a list of elements.
  #   Vector[7, 4, ...]
  #
  def SparseVector.[](*obj)
    new convert_to_hash(obj, copy = false), obj.size
  end

  #
  # Creates a sparse vector from an Array, Vector or Hash.  The optional second argument specifies
  # whether the array itself or a copy is used internally.  Copy only applies if obj is a Hash since
  # an Array or Vector will need to be converted into a hash.  Length may be supplied if obj is a Hash.
  #
  def SparseVector.elements(obj, copy = true, length=nil)
    s = length.nil? ? (obj.is_a?(Array) || obj.is_a?(Vector) ? obj.size : nil) : length
    new convert_to_hash(obj, copy), s
  end

  #
  # SparseVector.new is private; use SparseVector[] or SparseVector.elements to create.
  #
  def initialize(hash, length=nil)
    # No checking is done at this point.
    @elements = hash
    @elements.default = 0
    @size = if length.nil?
      @elements.empty? ? 0 : @elements.keys.max + 1
    else
      length
    end
  end

  #
  # Returns element number +i+ (starting at zero) of the vector.
  #
  def [](i)
    i >= size ? nil : @elements[i]
  end
  alias element []
  alias component []

  def []=(i, v)
    # make sure we take care of 0 values correctly
    if v == 0 || v.nil?
      if @elements.has_key?(i)
        @elements.delete(i)
      else
        0
      end
    else
      @elements[i] = v
    end
  end
  alias set_element []=
  alias set_component []=
  private :[]=, :set_element, :set_component

  #
  # Returns the number of elements (zeros and non-zeros) in the sparse vector.
  #
  def size; @size end

  #
  # Resize the sparse vector, possibly removing elements if val is less than
  # the current size.
  #
  def size=(val)
    if @size > val
      @elements.keys.each do |k|
        @elements.delete(k) if k >= val
      end
    end
    @size = val
  end

  #
  # Return the number of non-zero elements in the sparse vector
  #
  def nnz; @elements.size end

  def nz_indicies; @elements.keys.sort end

  #--
  # ENUMERATIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Iterate over the elements of this vector
  #
  # FIXME: figure out what to do with no block
  def each(&block)
    return to_enum(:each) unless block_given?
    size.times.each { |i| yield @elements[i] }
    self
  end

  #
  # Iterate over the non-zero elements of this vector
  #
  # FIXME: figure out what to do with no block
  def each_nz(&block)
    return to_enum(:each_nz) unless block_given?
    nz_indicies.each { |k| yield @elements[k] }
    self
  end

  #
  # Iterate over the elements (zero and non-zero) of this sparse vector and +v+ in conjunction.
  #
  # FIXME: figure out what to do with no block
  def each2(v) # :yield: e1, e2
    SparseVector.Raise ErrDimensionMismatch if size != v.size
    return to_enum(:each2, v) unless block_given?
    size.times do |i|
      yield @elements[i], v[i]
    end
  end

  #
  # Iterate over the non-zero elements of this vector and +v+ in conjunction.
  #
  # FIXME: figure out what to do with no block
  # FIXME: only works with another SparseVector
  def each2_nz(v) # :yield: e1, e2
    raise TypeError, "Integer is not like SparseVector" if v.kind_of?(Integer)
    SparseVector.Raise ErrDimensionMismatch if size != v.size
    return to_enum(:each2_nz, v) unless block_given?
    (nz_indicies + v.nz_indicies).uniq.sort.each do |i|
      yield @elements[i], v[i]
    end
  end

  #
  # Collects (as in Enumerable#collect) over the elements of this vector and +v+
  # in conjunction.
  #
  # FIXME: figure out what to do with no block
  def collect2(v) # :yield: e1, e2
    raise TypeError, "Integer is not like SparseVector" if v.kind_of?(Integer)
    SparseVector.Raise ErrDimensionMismatch if size != v.size
    return to_enum(:collect2, v) unless block_given?
    Array.new(size) do |i|
      yield @elements[i], v[i]
    end
  end

  #
  # Collects (as in Enumerable#collect) over the non-zero elements of this vector and +v+
  # in conjunction.
  #
  # FIXME: figure out what to do with no block
  # FIXME: only works with another SparseVector
  def collect2_nz(v) # :yield: e1, e2
    SparseVector.Raise ErrDimensionMismatch if size != v.size
    return to_enum(:collect2_nz, v) unless block_given?

    keys = (nz_indicies + v.nz_indicies).uniq.sort

    array = Array.new(size)
    keys.each do |i|
      array[i] = yield @elements[i], v[i]
    end
    array
  end

  #
  # Like Array#collect.
  #
  def collect(&block) # :yield: e
    return to_enum(:collect) unless block_given?
    els = {}
    @elements.each_pair do |k,v|
      els[k] = yield v
    end
    SparseVector.elements(els, false, size)
  end
  alias map collect

  #
  # Like SparseVector#collect2, but returns a SparseVector instead of an Array.
  #
  def map2(v, &block) # :yield: e1, e2
    return to_enum(:map2, v) unless block_given?
    els = collect2(v, &block)
    SparseVector.elements(els, false, size)
  end

  #
  # Like SparseVector#collect2, but returns a SparseVector instead of a Hash.
  #
  def map2_nz(v, &block) # :yield: e1, e2
    return to_enum(:map2_nz, v) unless block_given?
    els = collect2_nz(v, &block)
    SparseVector.elements(els, false)
  end

  #--
  # COMPARING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns +true+ iff the two sparse vectors have the same elements in the same order.
  #
  def ==(other)
    return false unless SparseVector === other
    @elements == other.elements && size == other.size
  end

  def eql?(other)
    return false unless SparseVector === other
    @elements.eql?(other.elements) && size.eql?(other.size)
  end

  #
  # Return a copy of the sparse vector.
  #
  def clone
    SparseVector.elements(@elements, true, size)
  end

  #
  # Return a hash-code for the sparse vector.
  #
  def hash
    @elements.hash
  end

  #--
  # ARITHMETIC -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Multiplies the vector by +x+, where +x+ is a number or another vector.
  #
  # FIXME: Numeric case should not copy elements
  def *(x)
    case x
    when Numeric
      collect { |v| v * x }
    when SparseMatrix
      raise "NOT IMPLEMENTED"
      SpraseMatrix.column_vector(self) * x
    when Matrix
      raise "NOT IMPLEMENTED"
      Matrix.column_vector(self) * x
    when SparseVector
      SparseVector.Raise ErrOperationNotDefined, "*", self.class, x.class
    when Vector
      Vector.Raise ErrOperationNotDefined, "*", self.class, x.class
    else
      raise "NOT IMPLEMENTED"
      apply_through_coercion(x, __method__)
    end
  end

  #
  # SparseVector addition.
  #
  def +(v)
    case v
    when SparseVector
      SparseVector.Raise ErrDimensionMismatch if size != v.size
      els = collect2_nz(v) { |v1, v2|
        v1 + v2
      }
      SparseVector.elements(els, false, size)
    when Vector
      SparseVector.Raise ErrDimensionMismatch if size != v.size
      els = collect2(v) { |v1, v2|
        v1 + v2
      }
      SparseVector.elements(els, false, size)
    when SparseMatrix
      SparseMatrix.column_vector(self) + v
    else
      raise "NOT IMPLEMENTED"
      apply_through_coercion(v, __method__)
    end
  end

  #
  # SparseVector subtraction.
  #
  def -(v)
    case v
    when SparseVector
      SparseVector.Raise ErrDimensionMismatch if size != v.size
      els = collect2_nz(v) {|v1, v2|
        v1 - v2
      }
      SparseVector.elements(els, false, size)
    when Vector
      SparseVector.Raise ErrDimensionMismatch if size != v.size
      els = collect2(v.to_sv) {|v1, v2|
        v1 - v2
      }
      SparseVector.elements(els, false, size)
    when SparseMatrix
      SparseMatrix.column_vector(self) - v
    when Matrix
      SparseMatrix.column_vector(self) - v.to_sm
    else
      raise "NOT IMPLEMENTED"
      apply_through_coercion(v, __method__)
    end
  end

  #
  # SparseVector division.
  #
  # FIXME: Numeric case should not copy elements
  def /(x)
    case x
    when Numeric
      collect { |v| v / x }
    when Matrix, Vector # covers SparseMatrix and SparseVector
      SparseVector.Raise ErrOperationNotDefined, "/", self.class, x.class
    else
      raise "NOT IMPLEMENTED"
      apply_through_coercion(x, __method__)
    end
  end

  #--
  # VECTOR FUNCTIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns the inner product of this vector with the other.
  #   SparseVector[4,7].inner_product SparseVector[10,1]  => 47
  #
  def inner_product(v)
    SparseVector.Raise ErrDimensionMismatch if size != v.size

    p = 0
    each2_nz(v) do |v1,v2|
      p += v1*v2
    end
    p
  end

  #
  # Returns the modulus (Pythagorean distance) of the vector.
  #   Vector[5,8,2].r => 9.643650761
  #
  def r
    Math.sqrt(@elements.values.inject(0) { |v, e| v + ( e * e ) } )
  end

  #--
  # CONVERTING
  #++

  #
  # Creates a single-row sparse matrix from this sparse vector.
  #
  def covector
    SparseMatrix.row_vector(self)
  end

  #
  # Returns the elements of the sparse vector in an array.
  #
  def to_a
    a = Array.new(size).fill(0)
    @elements.each_pair { |k,v| a[k] = v }
    a
  end

  #
  # Returns a Vector with the same elements as 
  #
  def to_v
    Vector.elements(to_a)
  end

  def elements_to_f
    warn "#{caller(1)[0]}: warning: SparseVector#elements_to_f is deprecated"
    @elements.each_pair { |k,v| @elements[k] = v.to_f }
  end

  def elements_to_i
    warn "#{caller(1)[0]}: warning: SparseVector#elements_to_i is deprecated"
    @elements.each_pair { |k,v| @elements[k] = v.to_i }
  end

  def elements_to_r
    warn "#{caller(1)[0]}: warning: SparseVector#elements_to_r is deprecated"
    @elements.each_pair { |k,v| @elements[k] = v.to_r }
  end

  #--
  # PRINTING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Overrides Object#to_s
  #
  def to_s
    "SparseVector[" + @elements.join(", ") + "]"
  end

  #
  # Overrides Object#inspect
  #
  def inspect
    str = "SparseVector"+@elements.inspect+", #{size}"
  end
end