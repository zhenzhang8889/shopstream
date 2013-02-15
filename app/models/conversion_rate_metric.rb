class ConversionRateMetric < Analyzing::Metric
  events :orders, :requests
  calculate { orders.count / requests.distinct("data.client_id").count }
end
