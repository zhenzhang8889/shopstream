class ConversionRateMetric < Analyzing::Metric
  events :orders, :requests
  calculate { orders.count / requests.where("data.unique_day" => true).count.to_f }
end
