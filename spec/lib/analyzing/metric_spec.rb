require 'spec_helper'

describe Analyzing::Metric do
  let(:klass) do
    Class.new(Analyzing::Metric) do
      cattr_accessor :name
      self.name = 'SalesMetric'
    end
  end

  let(:object) do
    double
  end

  let(:period) do
    1.day.ago..Time.now
  end

  let(:metric) do
    klass.new object: object, period: period, extra: 1
  end

  it 'is a gauge' do
    expect(klass.ancestors).to include Analyzing::Gauge
  end

  describe '.calculate' do
    it 'sets the block to perform metric value calculation' do
      blk = ->{ 1 }
      klass.calculate(&blk)
      expect(klass.calculate).to eq blk
    end
  end

  describe '#value' do
    before do
      metric.stub(:events) { { requests: [double.as_null_object] } }
    end

    it 'executes block' do
      blk_double = double
      klass.calculate { blk_double.test }
      blk_double.should_receive(:test)
      metric.value
    end

    it 'returns block return value' do
      klass.calculate { 1 }
      expect(metric.value).to eq 1
    end

    it 'executes block in context of associated events' do
      klass.calculate { requests.count }
      expect(metric.value).to eq 1
    end

    it 'returns 0 in case of division by 0' do
      klass.calculate { 1 / 0 }
      expect(metric.value).to eq 0
      klass.calculate { 0 / 1 }
      expect(metric.value).to eq 0
    end
  end

  describe '#change' do
    context 'when metric was initialized with change option' do
      let(:metric) do
        klass.new(object: object, period: period, change: 1)
      end
      
      before do
        metric.stub(:value).and_return(100)
      end

      it 'computes metric value for previous period' do
        metric.should_receive(:dup_for).with(period: period.prev(1), change: nil).and_return(double(value: 50))
        metric.change
      end

      it 'compares current value with previous value' do
        metric.stub(:dup_for).and_return(double(value: 50))
        expect(metric.change).to eq(1)
      end
    end
  end

  describe '#dup_for' do
    let(:another_metric) do
      metric.dup_for(period: 1..6)
    end

    it 'returns a new metric for options specified' do
      expect(another_metric.object).to eq object
      expect(another_metric.period).to eq 1..6
      expect(another_metric.options).to eq object: object, period: 1..6, extra: 1
    end
  end
end

describe Analyzing::Metric::ComputationContext do
  subject { described_class.new(a: 1, b: 2, c: 3) }

  describe '#compute' do
    it 'evaluates the block' do
      blk_double = double
      blk_double.should_receive(:test)
      subject.compute { blk_double.test }
    end

    it 'returns evaluation result' do
      expect(subject.compute { 1 }).to eq 1
    end

    it 'evaluates the block in the context of locals' do
      expect(subject.compute { a }).to eq 1
    end

    it 'catches division by zero and returns 0' do
      expect(subject.compute { 1 / 0 }).to eq 0
    end
  end

  describe '#method_missing' do
    context 'local is present' do
      it 'returns the value of local, wrapped into EventSet' do
        expect(subject.a).to eq Analyzing::Metric::ComputationContext::EventSet.new(1)
      end
    end

    context 'local is not preset' do
      it 'raises an error' do
        expect { subject.d }.to raise_exception NoMethodError
      end
    end
  end
end
