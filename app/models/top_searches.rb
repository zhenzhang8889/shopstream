class TopSearches < Analyzing::Top
  event :requests
  extend_query { |q| q.nin('data.search_query' => [nil, '']) }
  pipe project: { query: "$data.search_query" }
  pipe group: { _id: "$query", count: { "$sum" => 1 } }
  pipe sort: { count: -1 }
end
