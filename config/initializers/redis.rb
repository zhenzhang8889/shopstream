if ENV['REDISTOGO_URL']
  uri = URI.parse ENV['REDISTOGO_URL']
  $redis = Redis.new host: uri.host, port: uri.port, password: uri.password, driver: :hiredis
else
  $redis = Redis.new driver: :hiredis
end

Redis.current = $redis
Rails.cache.instance_variable_set(:@data, $redis)
