Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify, 
           ShopifyApp.configuration.api_key, 
           ShopifyApp.configuration.secret,
           scope: 'read_orders, read_products, read_script_tags, write_script_tags',
           setup: ->(env) {
                    params = Rack::Utils.parse_query(env['QUERY_STRING'])
                    site_url = "https://#{params['shop']}"
                    env['omniauth.strategy'].options[:client_options][:site] = site_url
                  }
end
