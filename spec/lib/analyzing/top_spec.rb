require 'spec_helper'

describe Analyzing::Top do
  let(:klass) do
    Class.new(Analyzing::Top) do
      cattr_accessor :name
      self.name = 'TopThings'
    end
  end

  let(:object) { double }
  let(:period) { 1.day.ago..Time.now }
  let(:top) { klass.new object: object, period: period }

  it 'is a gauge' do
    expect(klass.ancestors).to include Analyzing::Gauge
  end

  describe '.event' do
    it 'sets the event to compute top on' do
      klass.event(:requests)
      expect(klass.event).to eq :requests
    end
  end

  describe '.extend_query' do
    it 'sets the block to extend the query' do
      blk = ->(q){ q.abc }
      klass.extend_query(&blk)
      expect(klass.extend_query).to eq blk
    end
  end

  describe '.pipe' do
    it 'appends the pipeline operator to the pipe' do
      klass.pipe("a" => 1)
      expect(klass.pipeline).to eq ["a" => 1]
      klass.pipe("b" => 2)
      expect(klass.pipeline).to eq [{"a" => 1}, {"b" => 2}]
    end

    it 'transforms symbol keys into proper operator names' do
      klass.pipe(a: 1)
      expect(klass.pipeline.first).to eq "$a" => 1
    end
  end

  describe '#items' do
    let(:event) { double(collection: double) }
    let(:collection) { event.collection }
    let(:pipeline) { ["$match" => { "a" => 1 }] }

    before do
      top.stub(:event) { event }
      top.stub(:pipeline) { pipeline }
    end

    it 'runs the aggregation' do
      collection.should_receive(:aggregate).with(pipeline)
      top.items
    end

    it 'returns the aggregation results' do
      result = [{"_id" => "abc", "a" => 1}]
      collection.should_receive(:aggregate).with(pipeline).and_return(result)
      expect(top.items).to eq result
    end
  end

  describe '#event' do
    let(:demos_query) { double }

    before do
      klass.event :demos
      top.stub(:events) { { demos: demos_query } }
    end

    it 'returns event query' do
      expect(top.event).to eq demos_query
    end

    context 'when the query is extended' do
      let(:query_extender) { ->(q) { q.where(a: 1) } }
      before { klass.extend_query(&query_extender) }

      it 'applies extension on the query' do
        new_query = double
        demos_query.should_receive(:where).with(a: 1).and_return(new_query)
        expect(top.event).to eq new_query
      end
    end
  end

  describe '#pipeline' do
    let(:event) { double(query: double(selector: {"a" => 1})) }
    before { top.stub(:event) { event } }

    it 'prepends the event query to the pipeline' do
      expect(top.pipeline).to eq ["$match" => { "a" => 1 }]
    end

    it 'returns the user defined pipeline' do

    end
  end
end
