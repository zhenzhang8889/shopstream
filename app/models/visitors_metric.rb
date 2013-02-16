class VisitorsMetric < Analyzing::Metric
  events :requests
  calculate { requests.distinct("data.client_id").count }
end
