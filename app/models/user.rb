class User
  include Mongoid::Document
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
    :token_authenticatable, :validatable

  field :email, type: String, default: ''
  field :encrypted_password, type: String, default: ''

  field :reset_password_token, type: String
  field :reset_password_sent_at, type: Time

  field :remember_created_at, type: Time

  field :authentication_token, type: String

  has_many :shops

  before_save :ensure_authentication_token
end
