require 'spec_helper'

describe Analyzing::Eventful do
  let(:klass) do
    Class.new do
      include Mongoid::Document
      include Analyzing::Eventful
    end
  end

  let(:model) do
    klass.new
  end

  describe '.has_events' do
    before do
      klass.has_events :requests
    end

    it 'appends specifies event types to the list of supported events' do
      expect(klass.event_types).to include :request
    end

    it 'creates the associations' do
      expect(klass.reflect_on_association(:request_events)).to be_present
    end

    it 'adds the event to subclasses' do
      another_class = Class.new(klass)
      klass.has_events :orders
      expect(another_class.event_types).to include :order
    end
  end

  describe '#event_associations' do
    before do
      klass.has_events :requests
    end

    it 'returns event associations' do
      requests = double
      model.stub(:request_events) { requests }
      expect(model.event_associations).to eq request: requests
    end
  end

  describe '#event_associations_between' do
    before do
      klass.has_events :requests
    end

    context 'when time range is passed' do
      it 'returns event associations for that period' do
        requests = double
        period = 1..2
        period_requests = double
        model.stub(:request_events) { requests }
        requests.should_receive(:between).with(created_at: period).and_return(period_requests)
        expect(model.event_associations_between(period)).to eq request: period_requests
      end
    end
  end

  describe '.inherited ' do
    before do
      klass.has_events :requests
    end

    let(:new_class) do
      Class.new(klass)
    end

    it 'preserves supported event types from the parent' do
      expect(new_class.event_types).to eq klass.event_types
    end
  end
end
