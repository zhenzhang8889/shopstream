class TopLinks < Analyzing::Top
  event :requests
  extend_query { |q| q.ne('data.referrer_host' => [nil, '']) }
  pipe project: { ref_host: "$data.referrer_host" }
  pipe group: { _id: "$ref_host", count: { "$sum" => 1 } }
  pipe match: { _id: { "$ne" => nil } }
  pipe sort: { count: -1 }
  pipe limit: 10
end
