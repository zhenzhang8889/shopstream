task migrate_cube_data: :environment do
  session = Mongoid.session(:default)
  collections = session.collection_names

  puts "-- dropping unneeded collections"

  to_drop = ["cube_compute_events", "cube_compute_metrics"]
  to_drop += collections.select { |c| c.match(/^shop_\w+_metrics$/) }

  puts to_drop

  to_drop.each do |c|
    session[c].drop
  end

  orders = collections.select { |c| c.match(/^shop_\w+_new_orders_events$/) }
  requests = collections.select { |c| c.match(/^shop_\w+_requests_events$/) }

  Shop.send(:define_method, :refresh_gauges) { nil }

  puts "-- processing orders..."

  orders.each do |col|
    token = col.match(/^shop_(\w+)_new_orders_events$/)[1]
    shop = Shop.where(token: token).first
    collection = session[col]

    puts "migrating orders for #{shop.id} (from #{collection})..." if shop

    collection.find.each do |doc|
      t = doc['t']
      d = doc['d']
      data = d.merge(timestamp: t)
      shop.track_order(data)
    end if shop

    puts "dropping #{col}..."
    collection.drop
  end

  puts "processing requests..."

  requests.each do |col|
    puts "dropping #{col}..."
    session[col].drop
  end
end
