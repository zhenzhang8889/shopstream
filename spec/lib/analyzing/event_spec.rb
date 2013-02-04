require 'spec_helper'

describe Analyzing::Event do
  let(:event_class) do
    Class.new do
      cattr_accessor :name
      self.name = 'LoadEvent'
      include Analyzing::Event
    end
  end

  let(:load_event) { event_class.new }

  describe '.included' do
    it 'includes mongoid document' do
      expect(event_class.ancestors).to include Mongoid::Document
    end

    it 'includes created timestamps' do
      expect(event_class.ancestors).to include Mongoid::Timestamps::Created
    end

    it 'includes inline embeds' do
      expect(event_class.ancestors).to include Analyzing::Mongoid::InlineEmbeds
    end

    it 'creates a desc index on created_at' do
      expect(event_class.index_options).to have_key(created_at: -1)
    end
  end

  describe '.event_for' do
    it 'creates a relation' do
      event_class.event_for :thing
      expect(event_class.relations['thing']).to be_present
    end
  end

  describe '.type' do
    it 'returns the type of event' do
      expect(event_class.type).to be :load
    end
  end
end
