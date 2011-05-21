module CoercionHelper # :nodoc:
  #
  # Applies the operator +oper+ with argument +obj+
  # through coercion of +obj+
  #
  def apply_through_coercion(obj, oper)
    coercion = obj.coerce(self)
    raise TypeError unless coercion.is_a?(Array) && coercion.length == 2
    coercion[0].public_send(oper, coercion[1])
  rescue
    raise TypeError, "#{obj.inspect} can't be coerced into #{self.class}"
  end
  private :apply_through_coercion

  #
  # Helper method to coerce a value into a specific class.
  # Raises a TypeError if the coercion fails or the returned value
  # is not of the right class.
  # (from Rubinius)
  #
  def self.coerce_to(obj, cls, meth) # :nodoc:
    return obj if obj.kind_of?(cls)

    begin
      ret = obj.__send__(meth)
    rescue Exception => e
      raise TypeError, "Coercion error: #{obj.inspect}.#{meth} => #{cls} failed:\n" \
                       "(#{e.message})"
    end
    raise TypeError, "Coercion error: obj.#{meth} did NOT return a #{cls} (was #{ret.class})" unless ret.kind_of? cls
    ret
  end

  def self.coerce_to_int(obj)
    coerce_to(obj, Integer, :to_int)
  end
end