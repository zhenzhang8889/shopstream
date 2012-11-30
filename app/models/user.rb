class User
  include Mongoid::Document
  include Mongoid::Timestamps

  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
    :token_authenticatable, :validatable

  field :email, type: String, default: ''
  field :name, type: String, default: ''
  field :encrypted_password, type: String, default: ''

  field :reset_password_token, type: String
  field :reset_password_sent_at, type: Time

  field :remember_created_at, type: Time

  field :confirmation_token, type: String
  field :confirmed_at, type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email, type: String

  field :authentication_token, type: String

  validates :name, presence: true

  has_many :shops

  before_save :ensure_authentication_token

  def hours_since_signup
    seconds = Time.now - created_at

    (seconds / 60 / 60).to_i
  end

  def days_since_signup
    (hours_since_signup / 24).to_i
  end

  def should_receive_no_store_notification?
    shops.blank? && [1 * 24, 3 * 24, 7 * 24].include?(hours_since_signup)
  end

  def self.interested_in_no_store_notification
    User.all.to_a.select &:should_receive_no_store_notification?
  end
end
