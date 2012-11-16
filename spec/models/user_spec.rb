require 'spec_helper'

describe User do
  let(:user) { FactoryGirl.create :user }

  it { should have_many(:shops) }
  it { should validate_presence_of(:name) }
end
