class VisitorsMetric < Analyzing::Metric
  events :requests
  calculate { requests.where("data.unique_day" => true).count }
end
