module SM
  module ConversionHelper # :nodoc:
    #
    # Converts the obj to Hash. If copy is set to true
    # a copy of obj will be made if necessary.
    #
    def convert_to_hash(obj, copy = false) # :nodoc:
      case obj
      when Hash
        copy ? obj.dup : obj
      when Array
        h = Hash.new(0)
        obj.each_with_index { |j,i| h[i] = j unless j == 0 }
        h
      when Vector
        hash = Hash.new(0)
        obj.to_a.each_with_index { |j,i| h[i] = j unless j == 0 }
        h
      else
        raise "NOT IMPLEMENTED"
        # begin
        #   converted = obj.to_ary
        # rescue Exception => e
        #   raise TypeError, "can't convert #{obj.class} into an Array (#{e.message})"
        # end
        # raise TypeError, "#{obj.class}#to_ary should return an Array" unless converted.is_a? Array
        # converted
      end
    end

    #
    # Converts an array into a hash dropping all of the 0 elements
    #
    def convert_array_to_sparse_hash
      hash = Hash.new(0)
      obj.to_a.each_with_index { |j,i| hash[i] = j unless j == 0 }
      hash
    end

    private :convert_to_hash, :convert_array_to_sparse_hash
  end
end