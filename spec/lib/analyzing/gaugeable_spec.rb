require 'spec_helper'

describe Analyzing::Gaugeable do
  class Top < Analyzing::Gauge
    kind :top, position: :start
  end

  class Metric < Analyzing::Metric
    kind :metric, position: :end
  end

  class TopProducts < Top; end
  class TopLinks < Top; end
  class SalesMetric < Metric; end

  let(:klass) do
    Class.new do
      include Mongoid::Document
      include Analyzing::Gaugeable
    end
  end

  describe '.has_gauges' do
    before { klass.has_gauges(:top, products: {}) }

    it 'adds the metadata to the class' do
      expect(klass.gauges[:tops][:products]).to be_present
    end

    it 'adds the right gauges' do
      expect(klass.gauges[:tops][:products]).to eq kind: :top, type: :products, klass: TopProducts, options: {}
    end

    it 'defines the getters' do
      expect(klass.new).to respond_to :top_products
    end

    it 'adds the gauges to subclasses' do
      another_class = Class.new(klass)
      klass.has_gauges(:top, links: {})
      expect(another_class.gauges).to eq klass.gauges
    end
  end

  describe '.has_top' do
    it 'calls has_gauges' do
      klass.should_receive(:has_gauges)
      klass.has_top(products: {})
    end

    it 'carries types and passes :top as kind' do
      klass.should_receive(:has_gauges).with(:top, products: {})
      klass.has_top(products: {})
    end
  end

  describe '.has_metric' do
    it 'calls has_gauges' do
      klass.should_receive(:has_gauges)
      klass.has_metric(sales: {})
    end

    it 'carries types and passes :top as kind' do
      klass.should_receive(:has_gauges).with(:metric, sales: {})
      klass.has_metric(sales: {})
    end
  end

  describe '.gauge_getter' do
    let(:gauge) { double.as_null_object }
    let(:model) { klass.new }
    before { klass.gauge_getter(:top_products, { klass: gauge, options: { a: 1} }) }

    it 'defines a getter' do
      expect(model).to respond_to :top_products
    end

    specify 'the getter constructs a new gauge with object and options' do
      gauge.should_receive(:new).with(a: 1, b: 2, period: 1..2, object: model)
      model.top_products(1..2, b: 2)
    end
  end

  describe '.inherited' do
    before { klass.has_gauges(:top, products: {}) }
    let(:new_class) { Class.new(klass) }

    it 'preserves supported gauge metadata' do
      expect(new_class.gauges).to eq klass.gauges
    end

    it 'preserves gauge getters' do
      expect(new_class.new).to respond_to :top_products
    end
  end
end
