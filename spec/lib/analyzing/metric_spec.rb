require 'spec_helper'

describe Analyzing::Metric do
  let(:klass) do
    Class.new(Analyzing::Metric) do
      cattr_accessor :name
      self.name = 'SalesMetric'
    end
  end

  let(:metric) do
    klass.new
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
