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
  # whether the array itself or a copy is used internally.  Copy on applies if obj is a Hash since
  # an Array or Vector will need to be converted into a hash.
  #
  def SparseVector.elements(obj, copy = true)
    s = obj.is_a?(Array) || obj.is_a?(Vector) ? obj.size : nil
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
    if v == 0 
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

  # FIXME: make protected?
  def sorted_keys; @elements.keys.sort end

  #--
  # ENUMERATIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Iterate over the elements of this vector
  #
  # FIXME: figure out what to do with no block
  def each(&block)
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:each) unless block_given?
    size.times.each { |i| yield @elements[i] }
    self
  end

  #
  # Iterate over the non-zero elements of this vector
  #
  # FIXME: figure out what to do with no block
  def each_nz(&block)
    raise "NOT IMPLEMENTED" unless block_given?
    # return to_enum(:each) unless block_given?
    sorted_keys.each { |k| yield @elements[k] }
    self
  end

  #
  # Iterate over the elements (zero and non-zero) of this sparse vector and +v+ in conjunction.
  #
  # FIXME: figure out what to do with no block
  def each2(v) # :yield: e1, e2
    SparseVector.Raise ErrDimensionMismatch if size != v.size
    raise "NOT IMPLEMENTED" unless block_given?
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
    # return to_enum(:each2, v) unless block_given?
    raise "NOT IMPLEMENTED" unless block_given?
    sk = sorted_keys
    v_sk = v.sorted_keys

    i_s = 0
    i_v = 0

    while i_s < sk.length || i_v < v_sk.length
      a = i_s < sk.length ? sk[i_s] : nil
      b = i_v < v_sk.length ? v_sk[i_v] : nil

      i = if a.nil? || (!b.nil? && a > b)
        i_v += 1
        b
      elsif b.nil? || (!a.nil? && a < b)
        i_s += 1
        a
      else # a == b
        i_s += 1
        i_v += 1
        a
      end

      yield @elements[i], v[i]
    end
  end

  #
  # Collects (as in Enumerable#collect) over the elements of this vector and +v+
  # in conjunction.
  #
  # FIXME: figure out what to do with no block
  def collect2(v) # :yield: e1, e2
    raise "NOT IMPLEMENTED" unless block_given?
    raise TypeError, "Integer is not like SparseVector" if v.kind_of?(Integer)
    SparseVector.Raise ErrDimensionMismatch if size != v.size
    # return to_enum(:collect2, v) unless block_given?
    Array.new(size) do |i|
      yield @elements[i], v[i]
    end
  end

  #
  # Collects (as in Enumerable#collect) over the elements of this vector and +v+
  # in conjunction.
  #
  # FIXME: figure out what to do with no block
  # FIXME: only works with another SparseVector
  def collect2_nz(v) # :yield: e1, e2
    SparseVector.Raise ErrDimensionMismatch if size != v.size
    # return to_enum(:collect2, v) unless block_given?
    raise "NOT IMPLEMENTED" unless block_given?

    h = Hash.new(0)
    sk = sorted_keys
    v_sk = v.sorted_keys

    i_s = 0
    i_v = 0

    while i_s < sk.length || i_v < v_sk.length
      a = i_s < sk.length ? sk[i_s] : nil
      b = i_v < v_sk.length ? v_sk[i_v] : nil

      i = if a.nil? || (!b.nil? && a > b)
        i_v += 1
        b
      elsif b.nil? ||(!a.nil? && a < b)
        i_s += 1
        a
      else # a == b
        i_s += 1
        i_v += 1
        a
      end

      h[i] = yield @elements[i], v[i]
    end

    h
  end

  #
  # Like Array#collect.
  #
  def collect(&block) # :yield: e
    raise "NOT IMPLEMENTED"
    # return to_enum(:collect) unless block_given?
    # els = @elements.collect(&block)
    # Vector.elements(els, false)
  end
  alias map collect

  #
  # Like Vector#collect2, but returns a Vector instead of an Array.
  #
  def map2(v, &block) # :yield: e1, e2
    raise "NOT IMPLEMENTED"
    # return to_enum(:map2, v) unless block_given?
    # els = collect2(v, &block)
    # Vector.elements(els, false)
  end

  #--
  # COMPARING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns +true+ iff the two sparse vectors have the same elements in the same order.
  #
  def ==(other)
    return false unless SparseVector === other
    @elements == other.elements
  end

  def eql?(other)
    return false unless SparseVector === other
    @elements.eql? other.elements
  end

  #
  # Return a copy of the sparse vector.
  #
  def clone
    SparseVector.elements(@elements)
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
  def *(x)
    case x
    when Numeric
      h = Hash.new(0)
      @elements.each_pair { |k,v| h[k] = v * x }
      SparseVector.elements(h, false)
    when Matrix
      raise "NOT IMPLEMENTED"
      # Matrix.column_vector(self) * x
    when SparseMatrix
      raise "NOT IMPLEMENTED"
      # SpraseMatrix.column_vector(self) * x
    when Vector
      Vector.Raise ErrOperationNotDefined, "*", self.class, x.class
    when SparseVector
      SparseVector.Raise ErrOperationNotDefined, "*", self.class, x.class
    else
      raise "NOT IMPLEMENTED"
      # apply_through_coercion(x, __method__)
    end
  end

  #
  # SparseVector addition.
  #
  def +(v)
    case v
    when SparseVector
      SparseVector.Raise ErrDimensionMismatch if size != v.size
      els = collect2(v) { |v1, v2|
        v1 + v2
      }
      SparseVector.elements(els, false)
    when Vector
      SparseVector.Raise ErrDimensionMismatch if size != v.size
      
      els = collect2(v) { |v1, v2|
        v1 + v2
      }
      SparseVector.elements(els, false)
    when Matrix
      Matrix.column_vector(self) + v
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
      SparseVector.elements(els, false)
    when Vector
      SparseVector.Raise ErrDimensionMismatch if size != v.size
      els = collect2(v) {|v1, v2|
        v1 - v2
      }
      SparseVector.elements(els, false)
    when Matrix
      SparseMatrix.column_vector(self) - v
    else
      raise "NOT IMPLEMENTED"
      apply_through_coercion(v, __method__)
    end
  end

  #
  # SparseVector division.
  #
  def /(x)
    case x
    when Numeric
      h = Hash.new(0)
      @elements.each_pair { |k,v| h[k] = v / x }
      SparseVector.elements(h, false)
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
    str = "SparseVector"+@elements.inspect
  end
end