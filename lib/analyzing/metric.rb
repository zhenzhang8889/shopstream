module Analyzing
  # Public: The metric gauge.
  #
  # Metrics are meant to calculate numeric values on the set of events,
  # limited to a specific time period.
  #
  # Examples
  #
  #   class SalesMetric < Analyzing::Metric
  #     events :orders
  #     calculate { orders.sum(:total) }
  #   end
  class Metric < Gauge
    kind :metric, position: :end
    delegate :calculated_as, to: 'self.class'

    class << self
      # Public: Define a block to perform metric value calculation. Inside the
      # block you can access related events just by calling a method with name
      # of plural event type (e.g. `orders` for `OrderEvent`).
      #
      # Examples
      #
      #   class AwesomeMetric < Analyzing::Metric
      #     calculate { orders.sum(:total) / requests.distinct(:client_id).count }
      #   end
      def calculate(&block)
        @block ||= nil
        @block = block if block_given?
        @block
      end
      alias_method :calculated_as, :calculate

      # Public: Declare dependent events.
      def events(*events)
        @events ||= nil
        @events = events if events.present?
        @events
      end
    end

    def _compute
      max
      change
      series
      value
    end

    # Public: Compute the value of the metric.
    def value
      @value ||= ComputationContext.new(events).compute(&calculated_as)
    end

    # Public: Calculate the max value.
    def max
      @max ||= begin
        maxes = []
        options[:max].times { |t| maxes << dup_for(max: nil, change: nil, series: nil, extend_cache_life: options[:max] - t, period: period.prev(t + 1)).compute }
        maxes.max
      end if options[:max]
    end

    # Public: Calculate change.
    def change
      @change ||= begin
        previous = dup_for(max: nil, change: nil, series: nil, period: period.prev(options[:change]))
        change = value / previous.compute.to_f

        if change.nan?
          0.0
        elsif change.infinite?
          1.0
        else
          change - 1
        end
      end if options[:change]
    end

    # Public: Compute series.
    def series
      @series ||= begin
        series = options[:series]
        step = series.delete(:step)

        periods = (series.fetch(:period) { period }).to_i.each_slice(step).select { |p| p.first != p.last }.map { |p| (p.first..(p.first + step)).to_time }

        Hash[periods.map do |per|
          [per.begin, dup_for(max: nil, change: nil, series: nil, period: per).compute]
        end]
      end if options[:series]
    end

    # Internal: Get the associated events. Used for caching.
    def events
      events = super
      types = self.class.events
      Hash[types.zip(events.values_at(*types))]
    end

    # Internal: Calculate the expiry term for cached value.
    def cache_expiry
      if options[:extend_cache_life]
        (1 + options[:extend_cache_life]) * super
      else
        super
      end
    end

    # Public: Get JSON representation.
    def to_json
      h = { value: compute }
      h[:max] = max if max
      h[:change] = change if change
      h[:series] = series if series
      h
    end

    # Internal: Computation context for metric value calculation.
    class ComputationContext
      # Internal: Initialize the context.
      #
      # locals - The Hash of event type -> event set.
      def initialize(locals = {})
        @locals = locals
      end

      # Internal: Execute the block in the context of locals.
      def compute(&block)
        if block_given?
          begin
            value = dup.instance_eval(&block).to_f
          rescue ZeroDivisionError
            value = 0.0
          end
          (value.blank? || value.nan? || value.infinite?) ? 0.0 : value
        end
      end

      def method_missing(meth, *args)
        if @locals.has_key?(meth)
          EventSet.new(@locals[meth])
        else
          super
        end
      end

      # Internal: The proxy to the set of event
      class EventSet
        attr_reader :set

        def initialize(set)
          @set = set
        end

        def method_missing(name, *args, &block)
          value = @set.send(name, *args, &block)
          value.is_a?(Fixnum) ? value.to_f : value
        end

        def ==(other)
          set == other.set
        end
      end
    end
  end
end
