class RevenuePerVisitorMetric < Analyzing::Metric
  events :orders, :requests
  calculate { orders.sum("data.total_price_usd") / requests.distinct("data.client_id").count }
end
