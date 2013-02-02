class Range
  # Calculate the difference between range end and start.
  def difference
    self.end - self.begin
  end

  # Create a new range with both begin and end substracted by difference.
  def prev(n)
    (self.begin - difference * n)..(self.end - difference * n)
  end

  # Convert range begin & end to integers.
  def to_i
    self.begin.to_i..self.end.to_i
  end

  # Convert range begin & end to times.
  def to_time
    Time.at(self.begin)..Time.at(self.end)
  end
end
