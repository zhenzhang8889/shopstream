task refresh_all_gauges: :environment do
  Shop.refresh_all_gauges
end
