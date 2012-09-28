class UserSerializer < ActiveModel::Serializer
  attributes :id, :email

  has_one :shop, embed: :ids
end
