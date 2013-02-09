require 'spec_helper'

describe Analyzing::Gaugeable do
  class Top < Analyzing::Gauge
    kind :top, position: :start
  end

  class Metric < Analyzing::Gauge
    kind :metric, position: :end
  end

  class TopSuits < Top; end
  class TopRecords < Top; end
  class LolsMetric < Metric; end

  let(:klass) do
    Class.new do
      include Mongoid::Document
      include Analyzing::Gaugeable
    end
  end

  let(:model) { klass.new }

  describe '#gauges' do
    let(:top_suits) { double }
    let(:top_records) { double }
    let(:lols_metric) { double }

    before do
      klass.has_top suits: {}, records: {}
      klass.has_metrics lols: {}
      model.stub(top_suits: top_suits, top_records: top_records, lols_metric: lols_metric)
    end

    it 'returns gauge set of gauges grouped by kind' do
      expect(model.gauges).to eq(
        tops: { suits: top_suits, records: top_records },
        metrics: { lols: lols_metric }
      )
      expect(model.gauges).to be_kind_of Analyzing::Gaugeable::GaugeSet
      model.gauges.values.each { |v| expect(v).to be_kind_of Analyzing::Gaugeable::GaugeSet }
    end
  end

  describe '.has_gauges' do
    before { klass.has_gauges(:top, suits: {}) }

    it 'adds the metadata to the class' do
      expect(klass.gauges[:tops][:suits]).to be_present
    end

    it 'adds the right gauges' do
      expect(klass.gauges[:tops][:suits]).to eq kind: :top, type: :suits, klass: TopSuits, options: {}
    end

    it 'defines the getters' do
      expect(klass.new).to respond_to :top_suits
    end

    it 'adds the gauges to subclasses' do
      another_class = Class.new(klass)
      klass.has_gauges(:top, records: {})
      expect(another_class.gauges).to eq klass.gauges
    end
  end

  describe '.has_top' do
    it 'calls has_gauges' do
      klass.should_receive(:has_gauges)
      klass.has_top(suits: {})
    end

    it 'carries types and passes :top as kind' do
      klass.should_receive(:has_gauges).with(:top, suits: {})
      klass.has_top(suits: {})
    end
  end

  describe '.has_metric' do
    it 'calls has_gauges' do
      klass.should_receive(:has_gauges)
      klass.has_metric(lols: {})
    end

    it 'carries types and passes :top as kind' do
      klass.should_receive(:has_gauges).with(:metric, lols: {})
      klass.has_metric(lols: {})
    end
  end

  describe '.gauge_getter' do
    let(:gauge) { double.as_null_object }
    let(:model) { klass.new }
    before { klass.gauge_getter(:top_suits, { klass: gauge, options: { a: 1} }) }

    it 'defines a getter' do
      expect(model).to respond_to :top_suits
    end

    specify 'the getter constructs a new gauge with object and options' do
      gauge.should_receive(:new).with(a: 1, b: 2, period: 1..2, object: model)
      model.top_suits(1..2, b: 2)
    end
  end

  describe '.inherited' do
    before { klass.has_gauges(:top, suits: {}) }
    let(:new_class) { Class.new(klass) }

    it 'preserves supported gauge metadata' do
      expect(new_class.gauges).to eq klass.gauges
    end

    it 'preserves gauge getters' do
      expect(new_class.new).to respond_to :top_suits
    end
  end
end

describe Analyzing::Gaugeable::GaugeSet do
  it 'is a kind of hash' do
    expect(described_class.ancestors).to include Hash
  end

  describe '#refresh' do
    let(:value1) { double }
    let(:value2) { double }
    let(:set) { described_class[:key1, value1, :key2, value2] }

    it 'calls #refresh on all the values' do
      [value1, value2].each { |v| v.should_receive(:refresh) }
      set.refresh
    end
  end

  describe '#to_json' do
    let(:value1) { double }
    let(:value2) { double }
    let(:set) { described_class[:key1, value1, :key2, value2] }

    it 'calls #refresh on all the values' do
      [value1, value2].each { |v| v.should_receive(:to_json) }
      set.to_json
    end
  end
end
