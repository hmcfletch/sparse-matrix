class Matrix

  def to_sm
    SparseMatrix.rows(to_a)
  end

end