require 'spec_helper'

describe Analyzing::Gaugeable do
  class Top < Analyzing::Gauge
    kind :top, position: :start
  end

  class TopProducts < Top; end
  class TopLinks < Top; end

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

  describe '.gauge_getter' do
    before { klass.has_gauges(:top, products: {a: 1}) }
    let(:model) { klass.new }

    it 'defines a getter' do
      expect(klass.new).to respond_to :top_products
    end

    specify 'the getter constructs a new gauge with object and options' do
      TopProducts.should_receive(:new).with(a: 1, b: 2, period: 1..2, object: model)
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
