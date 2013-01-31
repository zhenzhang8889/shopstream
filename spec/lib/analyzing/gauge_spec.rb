require 'spec_helper'

describe Analyzing::Gauge do
  let(:klass) do
    Class.new(Analyzing::Gauge) do
      cattr_accessor :name, :kind, :class_name_kind
      self.name = 'SalesMetric'
      self.kind = :metric
      self.class_name_kind = :end
    end
  end

  it { should respond_to :object }
  it { should respond_to :period }
  it { should respond_to :options }

  describe '#events' do
    let(:order_events) do
      double
    end

    let(:gauge) do
      object = double(event_associations_between: { order: order_events })
      klass.new object: object, period: 1..2
    end

    it 'returns event associations for the gauge period' do
      gauge.object.should_receive(:event_associations_between).with(1..2)
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
    let(:gauge) do
      object = double.as_null_object
      klass.new object: object, period: 1..5
    end

    it 'calculates difference between period end and start' do
      expect(gauge.cache_expiry).to eq 4
    end
  end

  describe '#cache_key' do
    let(:gauge) do
      object = double(class: { name: 'DaTracked' }, id: 123, simple_cache_key: 'da_tracked/123')
      klass.new object: object, period: 1..5
    end

    it 'calculates the cache key' do
      expect(gauge.cache_key).to eq 'metric:sales:da_tracked/123:1-5'
    end
  end

  describe '#cache_store' do
    let(:gauge) do
      klass.new
    end

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
      before do
        klass.define_singleton_method(:kind) { :gauge }
      end

      context 'when gauge class name kind position is :start' do
        before do
          klass.name = 'GaugeSuperb'
          klass.define_singleton_method(:class_name_kind) { :start }
        end

        it 'returns the gauge type' do
          expect(klass.type).to eq :superb
        end
      end

      context 'when gauge class name kind position is :end' do
        before do
          klass.define_singleton_method(:class_name_kind) { :end }
        end

        it 'returns the gauge type' do
          expect(klass.type).to eq :superb
        end
      end
    end

    context 'when .kind is not defined' do
      it 'raises an exception' do
        expect { klass.type }.to raise_exception NotImplementedError
      end
    end

    context 'when .class_name_kind is not defined' do
      before do
        klass.define_singleton_method(:kind) { :gauge }
      end

      it 'raises an exception' do
        expect { klass.type }.to raise_exception NotImplementedError
      end
    end
  end
end
