class AveragePurchaseMetric < Analyzing::Metric
  events :orders, :requests
  calculate { orders.sum("data.total_price_usd") / requests.where("data.unique_day" => true).count }
end
