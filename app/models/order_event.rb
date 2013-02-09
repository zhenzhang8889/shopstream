class OrderEvent
  include Analyzing::Event

  event_for :shop

  embeds_one_inline :data do
    field :total_price, type: Float
    field :currency, type: String
    field :total_price_usd, type: Float
    field :name, type: String

    embeds_one_inline :customer do
      field :first_name, type: String
      field :last_name, type: String
      field :email, type: String
    end

    embeds_many_inline :line_items do
      field :name, type: String
      field :title, type: String
      field :price, type: Float
      field :quantity, type: Integer
      field :sku, type: String
    end
  end

  def self.sample_order(shop, time)
    prods = []
    (1..5).to_a.sample.times do
      name = (('a'..'z').to_a * 2).shuffle.take(3).join
      prods << { quantity: (1..3).to_a.sample, price: (99..999_00).to_a.sample / 100.0, name: name, title: name, sku: name.upcase }
    end
    total = prods.map { |p| p[:quantity] * p[:price] }.sum

    e = shop.track_order(total_price: total, total_price_usd: total, currency: 'USD', name: ('a'..'z').to_a.sample, line_items: prods)
    e.created_at = time.is_a?(Range) ? rand(time) : time
    e.save
    e
  end
end
