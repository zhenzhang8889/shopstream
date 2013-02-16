class TopProducts < Analyzing::Top
  event :orders
  pipe project: { li: "$data.line_items" }
  pipe unwind: "$li"
  pipe project: { sku: "$li.sku", name: "$li.name", revenue: { "$multiply" => ["$li.price", "$li.quantity"] } }
  pipe group: { _id: "$sku", purchases: { "$sum" => 1 }, revenue: { "$sum" => "$revenue" }, name: { "$first" => "$name" } }
  pipe match: { _id: { "$ne" => nil } }
  pipe sort: { purchases: -1 }
  pipe limit: 10
end
