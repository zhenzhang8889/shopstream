class OrderEvent
  include Analyzing::Event

  event_for :shop

  data do
    field :total_price, type: Float
    field :currency, type: String, default: 'USD'
    field :total_price_usd, type: Float, default: ->{ total_price }
    field :name, type: String

    embeds_one_inline :customer do
      field :first_name, type: String
      field :last_name, type: String
      field :email, type: String
    end

    embeds_many_inline :line_items do
      field :name, type: String
      field :title, type: String, default: ->{ name }
      field :price, type: Float, default: 0
      field :quantity, type: Integer, default: 1
      field :sku, type: String
    end
  end

  after_create :create_feed_item

  def create_feed_item
    shop.feed_items.create(activity_type: 'new_order', activity_attributes: data.attributes)
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
