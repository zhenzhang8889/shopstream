module Analyzing
  # Public: The top gauge.
  #
  # Tops are meant to rank some info extracted from events. Tops are all about
  # map/reduce and they take advantage of MongoDB's aggregation framework.
  # Learn more about it at http://docs.mongodb.org/manual/aggregation/
  #
  # Examples
  #
  #   class TopSomething < Analyzing::Top
  #     event :things
  #     pipe project: { "a" => 1 }
  #   end
  class Top < Gauge
    kind :top, position: :start
    delegate :extend_query, to: 'self.class'

    class << self
      # Public: Declare the type of event used in computing of the top.
      def event(event = nil)
        @event ||= nil
        @event = event if event
        @event
      end

      # Public: Define a block to extend the event query.
      #
      # Examples
      #
      #   class TopThings < Analyzing::Top
      #     event :abc
      #     extend_query { |q| q.where(a: 1) }
      #   end
      def extend_query(&block)
        @extend_query ||= nil
        @extend_query = block if block
        @extend_query
      end

      def pipe(operator = nil)
        @pipeline ||= []

        if operator
          @pipeline << Hash[operator.map do |k, v|
            k = "$#{k}" if k.is_a?(Symbol)
            [k, v]
          end]
        end

        @pipeline
      end
      alias_method :pipeline, :pipe
    end

    def _compute
      items
    end

    # Public: Get the top items.
    def items
      event.collection.aggregate(pipeline)
    end

    # Internal: Get the needed event association, extend the query if
    # appropriate.
    def event
      event = events[self.class.event]
      extend_query ? extend_query.call(event) : event
    end

    # Internal: Get associated events. Needed for cahing.
    def events
      { self.class.event => super[self.class.event] }
    end

    # Internal: Get the final aggregation pipeline.
    def pipeline
      self.class.pipeline.unshift("$match" => event.query.selector)
    end

    # Public: Get JSON representation.
    def to_json
      items
    end
  end
end
