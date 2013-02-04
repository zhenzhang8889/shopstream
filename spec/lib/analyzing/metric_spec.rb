require 'spec_helper'

describe Analyzing::Metric do
  let(:klass) do
    Class.new(Analyzing::Metric) do
      cattr_accessor :name
      self.name = 'SalesMetric'
    end
  end

  let(:object) { double }
  let(:period) { 1.day.ago..Time.now }
  let(:metric) { klass.new object: object, period: period, extra: 1 }

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

  describe '#max' do
    context 'when metric was initialized with max option' do
      let(:metric) { klass.new(object: object, period: period, max: 5) }
      let(:prev_metrics) { [double(value: 10), double(value: 25), double(value: 50), double(value: 99), double(value: 75)] }

      it 'computes metric value for each of previous periods' do
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[0])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[1])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[2])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[3])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[4])
        prev_metrics.each { |m| m.should_receive(:value) }
        metric.max
      end

      it 'returns the max value' do
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[0])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[1])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[2])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[3])
        metric.should_receive(:dup_for).with(max: nil).and_return(prev_metrics[4])
        expect(metric.max).to eq 99
      end
    end
  end

  describe '#change' do
    context 'when metric was initialized with change option' do
      let(:metric) { klass.new(object: object, period: period, change: 1) }
      let(:prev_metric) { double(value: 50) }

      before do
        metric.stub(:value).and_return(100)
        metric.stub(:dup_for).and_return(prev_metric)
      end

      it 'computes metric value for previous period' do
        metric.should_receive(:dup_for).with(period: period.prev(1), change: nil)
        metric.change
      end

      it 'compares current value with previous value' do
        expect(metric.change).to eq(1)
      end

      context 'when change is increase' do
        let(:prev_metric) { double(value: 25) }

        it 'reports positive change' do
          expect(metric.change).to be > 0
        end

        it 'returns percentage change' do
          expect(metric.change).to eq 3
        end
      end

      context 'when change is decrease' do
        let(:prev_metric) { double(value: 200) }

        it 'reports negative change' do
          expect(metric.change).to be < 0
        end

        it 'returns percentage change' do
          expect(metric.change).to eq(-0.5)
        end
      end

      context 'when previous value is the same' do
        let(:prev_metric) { double(value: 100) }

        it 'reports no change' do
          expect(metric.change).to eq 0
        end
      end

      context 'when change is increase from 0' do
        let(:prev_metric) { double(value: 0) }

        it 'reports 100% increase' do
          expect(metric.change).to eq 1
        end
      end

      context 'when change is decrease to 0' do
        before { metric.stub(:value).and_return(0) }

        it 'reports 100% decrease' do
          expect(metric.change).to eq(-1)
        end
      end
    end
  end

  describe '#dup_for' do
    let(:another_metric) { metric.dup_for(period: 1..6) }

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
