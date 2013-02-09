class Time
  # Rounds time to a given precision in seconds.
  def round(seconds = 60)
    Time.at((self.to_f / seconds).round * seconds)
  end

  # Floors time to a given precision in seconds.
  def floor(seconds = 60)
    Time.at((self.to_f / seconds).floor * seconds)
  end

  # Ceils time to a given precision in seconds.
  def ceil(seconds = 60)
    Time.at((self.to_f / seconds).ceil * seconds)
  end
end
