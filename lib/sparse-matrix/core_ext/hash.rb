class Hash

  #
  # Assumes that self is a hash of hashes and transposes the rows and columns
  #
  def transpose
    h = {}
    self.each_pair do |k1,v1|
      v1.each_pair do |k2,v2|
        h[k2] ||= {}
        h[k2][k1] = v2
      end
    end
    h
  end

end