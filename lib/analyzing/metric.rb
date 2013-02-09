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
        options[:max].times { maxes << dup_for(max: nil).value }
        maxes.max
      end if options[:max]
    end

    # Public: Calculate change.
    def change
      @change ||= begin
        previous = dup_for(period: period.prev(options[:change]), change: nil)
        change = value / previous.value.to_f

        if change.nan?
          0.0
        elsif change.infinite?
          1.0
        else
          change - 1
        end
      end if options[:change]
    end

    # Internal: Get the associated events. Used for caching.
    def events
      events = super
      types = self.class.events
      Hash[types.zip(events.values_at(*types))]
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
