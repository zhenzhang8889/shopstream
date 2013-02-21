class AveragePurchaseMetric < Analyzing::Metric
  events :orders, :requests
  calculate { orders.avg("data.total_price_usd") }
end
