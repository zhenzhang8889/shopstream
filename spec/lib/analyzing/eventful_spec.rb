require 'spec_helper'

describe Analyzing::Eventful do
  let(:klass) do
    Class.new do
      include Mongoid::Document
      include Analyzing::Eventful
    end
  end

  let(:model) { klass.new }

  describe '.has_events' do
    before { klass.has_events(:requests) }

    it 'appends specifies event types to the list of supported events' do
      expect(klass.event_types).to include :request
    end

    it 'creates the associations' do
      expect(klass.reflect_on_association(:request_events)).to be_present
    end

    it 'adds the event to subclasses' do
      another_class = Class.new(klass)
      klass.has_events(:orders)
      expect(another_class.event_types).to include :order
    end

    it 'creates the track method for the even type' do
      expect(model).to respond_to :track_request
    end
  end

  describe '.event_tracker' do
    let(:request_double) { double }
    let(:requests) { double }
    let(:model) { klass.new }

    before do
      klass.event_tracker(:requests)
      model.stub(:event_associations) { { requests: request_double } }
      model.stub(:refresh_gauges) { true }
      request_double.stub(:create) { requests }
    end

    it 'defines a tracker' do
      expect(model).to respond_to :track_request
    end

    specify 'the tracker creates a new event document' do
      request_double.should_receive(:create).with(a: 1, b: 2, c: 3)
      model.track_request(a: 1, b: 2, c: 3)
    end

    specify 'the tracker returns created event' do
      expect(model.track_request(a: 1, b: 2, c: 3)).to eq requests
    end

    specify 'the tracker refreshes gauges if there are any' do
      model.should_receive(:refresh_gauges)
      model.track_request(a: 1, b: 2, c: 3)
    end
  end

  describe '#event_associations' do
    before { klass.has_events :requests }

    it 'returns event associations' do
      requests = double
      model.stub(:request_events) { requests }
      expect(model.event_associations).to eq requests: requests
    end
  end

  describe '#event_associations_between' do
    before { klass.has_events :requests }

    context 'when time range is passed' do
      it 'returns event associations for that period' do
        requests = double
        period = 1..2
        period_requests = double
        model.stub(:request_events) { requests }
        requests.should_receive(:between).with(created_at: period).and_return(period_requests)
        expect(model.event_associations_between(period)).to eq requests: period_requests
      end
    end
  end

  describe '.inherited ' do
    before { klass.has_events :requests }
    let(:new_class) { Class.new(klass) }

    it 'preserves supported event types from the parent' do
      expect(new_class.event_types).to eq klass.event_types
    end

    it 'preserves event trackers' do
      expect(new_class.new).to respond_to :track_request
    end
  end
end
