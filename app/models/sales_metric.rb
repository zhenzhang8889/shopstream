class SalesMetric < Analyzing::Metric
  events :orders
  calculate { orders.sum("data.total_price") }
end
