FactoryGirl.define do
  factory :shop do
    user
    token 'abcdef'
    name Faker::Company.name
    domain Faker::Internet.domain_name
    timezone 'UTC'
  end

  factory :shopify_shop, parent: :shop, class: ShopifyShop do
    shopify_id 123
    shopify_token 'abcdef'
    shopify_attributes({ domain: Faker::Internet.domain_name, name: Faker::Company.name, timezone: '(UTC+0) UTC' }.with_indifferent_access)
  end
end
