class Vector

  def to_sv
    SparseVector.elements(to_a)
  end

end