class User
  include Mongoid::Document
  devise :token_authenticatable

  field :authentication_token, type: String

  has_one :shop

  before_save :ensure_authentication_token
end
