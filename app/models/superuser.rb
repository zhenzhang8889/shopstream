class Superuser
  include Mongoid::Document
  devise :database_authenticatable, :rememberable

  ## Database authenticatable
  field :email, type: String, default: ''
  field :encrypted_password, type: String, default: ''

  validates_presence_of :email
  validates_presence_of :encrypted_password

  ## Rememberable
  field :remember_created_at, type: Time
end
