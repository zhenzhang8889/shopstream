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

  describe '.events' do
    it 'sets the dependent events' do
      expect(klass.events(:a)).to eq [:a]
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
      let(:prev_metrics) { [double(compute: 10), double(compute: 25), double(compute: 50), double(compute: 99), double(compute: 75)] }

      it 'computes metric value for each of previous periods' do
        5.times do |t|
          metric.should_receive(:dup_for).with(max: nil, change: nil, series: nil,extend_cache_life: 5 - t, period: period.prev(t + 1)).and_return(prev_metrics[t])
        end

        metric.max
      end

      it 'returns the max value' do
        5.times do |t|
          metric.should_receive(:dup_for).with(max: nil, change: nil, series: nil, extend_cache_life: 5 - t, period: period.prev(t + 1)).and_return(prev_metrics[t])
        end

        expect(metric.max).to eq 99
      end
    end
  end

  describe '#change' do
    context 'when metric was initialized with change option' do
      let(:metric) { klass.new(object: object, period: period, change: 1) }
      let(:prev_metric) { double(compute: 50) }

      before do
        metric.stub(:value).and_return(100)
        metric.stub(:dup_for).and_return(prev_metric)
      end

      it 'computes metric value for previous period' do
        metric.should_receive(:dup_for).with(max: nil, change: nil, series: nil, period: period.prev(1))
        metric.change
      end

      it 'compares current value with previous value' do
        expect(metric.change).to eq(1)
      end

      context 'when change is increase' do
        let(:prev_metric) { double(compute: 25) }

        it 'reports positive change' do
          expect(metric.change).to be > 0
        end

        it 'returns percentage change' do
          expect(metric.change).to eq 3
        end
      end

      context 'when change is decrease' do
        let(:prev_metric) { double(compute: 200) }

        it 'reports negative change' do
          expect(metric.change).to be < 0
        end

        it 'returns percentage change' do
          expect(metric.change).to eq(-0.5)
        end
      end

      context 'when previous value is the same' do
        let(:prev_metric) { double(compute: 100) }

        it 'reports no change' do
          expect(metric.change).to eq 0
        end
      end

      context 'when change is increase from 0' do
        let(:prev_metric) { double(compute: 0) }

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

  describe '#series' do
    context 'when the metric was initialized with series option' do
      let(:period) { Time.now.beginning_of_day..Time.now.end_of_day.ceil }
      let(:subperiod1) { period.begin..(period.begin + 12.hours) }
      let(:subperiod2) { (period.begin + 12.hours)..period.end }
      let(:metric) { klass.new(object: object, period: period, series: { step: 12.hours }) }
      let(:prev_metric1) { double(compute: 10) }
      let(:prev_metric2) { double(compute: 15) }

      before do
        metric.stub(:dup_for).with(max: nil, change: nil, series: nil, period: subperiod1) { prev_metric1 }
        metric.stub(:dup_for).with(max: nil, change: nil, series: nil, period: subperiod2) { prev_metric2 }
      end

      it 'slices the period into steps and computes value for each' do
        metric.should_receive(:dup_for).with(max: nil, change: nil, series: nil, period: subperiod1) { prev_metric1 }
        metric.should_receive(:dup_for).with(max: nil, change: nil, series: nil, period: subperiod2) { prev_metric2 }
        prev_metric1.should_receive(:compute)
        prev_metric2.should_receive(:compute)

        metric.series
      end

      it 'returns a hash of period begin -> metric value' do
        expect(metric.series).to eq({
          subperiod1.begin => 10,
          subperiod2.begin => 15
        })
      end
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
