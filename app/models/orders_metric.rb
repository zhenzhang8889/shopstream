class OrdersMetric < Analyzing::Metric
  events :orders
  calculate { orders.count }
end
