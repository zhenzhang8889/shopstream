require 'spec_helper'

describe Analyzing::Gauge do
  let(:klass) do
    Class.new(Analyzing::Gauge) do
      cattr_accessor :name
      self.name = 'SalesMetric'
      kind :metric, position: :end
    end
  end

  it { should respond_to :object }
  it { should respond_to :period }
  it { should respond_to :options }

  describe '#dup_for' do
    let(:gauge) { klass.new(object: double, period: 1..2, extra: 1) }
    let(:another_gauge) { gauge.dup_for(period: 1..6) }

    it 'returns a new metric for options specified' do
      expect(another_gauge.object).to eq gauge.object
      expect(another_gauge.period).to eq 1..6
      expect(another_gauge.options).to eq object: gauge.object, period: 1..6, extra: 1
    end
  end

  describe '#events' do
    let(:order_events) { double }
    let(:object) { double(event_associations_between: { order: order_events }) }
    let(:gauge) { klass.new(object: object, period: 1..2) }

    it 'returns event associations for the gauge period' do
      object.should_receive(:event_associations_between).with(1..2)
      expect(gauge.events).to eq order: order_events
    end
  end

  describe '#cached' do
    let(:gauge) do
      gauge = klass.new
      gauge.stub(cache_key: 'abc', cache_expiry: 1)
      gauge.stub(cache_store: double)
      gauge
    end

    it 'fetches the cache entity' do
      blk = ->{ 1 }
      gauge.cache_store.should_receive(:fetch).with('abc', expires_in: 1, &blk)
      gauge.cached(&blk)
    end
  end

  describe '#cache_expiry' do
    let(:gauge) { klass.new object: double.as_null_object, period: 1..5 }

    it 'calculates difference between period end and start' do
      expect(gauge.cache_expiry).to eq 4
    end
  end

  describe '#cache_key' do
    let(:object) { double(class: { name: 'DaTracked' }, id: 123, simple_cache_key: 'da_tracked/123') }
    let(:gauge) { klass.new object: object, period: 1..5 }

    it 'calculates the cache key' do
      expect(gauge.cache_key).to eq 'metric:sales:da_tracked/123:1-5'
    end
  end

  describe '#cache_store' do
    let(:gauge) { klass.new }

    it 'returns default rails cache store' do
      expect(gauge.cache_store).to eq Rails.cache
    end
  end

  describe '.type' do
    let(:klass) do
      Class.new(Analyzing::Gauge) do
        cattr_accessor :name
        self.name = 'SuperbGauge'
      end
    end

    context 'when .kind is defined' do
      before { klass.kind :gauge }

      context 'when gauge class name kind position is :start' do
        before do
          klass.name = 'GaugeSuperb'
          klass.name_kind_position :start
        end

        it 'returns the gauge type' do
          expect(klass.type).to eq :superb
        end
      end

      context 'when gauge class name kind position is :end' do
        before { klass.name_kind_position :end }

        it 'returns the gauge type' do
          expect(klass.type).to eq :superb
        end
      end

      context 'when gauge class name kind position is not defined' do
        it 'returns the underscored class name' do
          expect(klass.type).to eq :superb_gauge
        end
      end
    end

    context 'when .kind is not defined' do
      it 'returns the underscored class name' do
        expect(klass.type).to eq :superb_gauge
      end
    end

  end

  describe '.inherited' do
    let(:new_class) { Class.new(klass) }

    it 'preserves gauge kind & kind position' do
      expect(new_class.kind).to eq klass.kind
      expect(new_class.name_kind_position).to eq klass.name_kind_position
    end
  end
end
