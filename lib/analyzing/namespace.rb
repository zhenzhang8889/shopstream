module Analyzing
  class Namespace
    class << self
      def key(key = nil)
        @key ||= nil
        @key = key if key
        @key
      end

      def events(*types)
        event_types.concat(types)
      end

      def event_ext(&block)
        @event_ext ||= nil
        @event_ext = block if block_given?
        @event_ext
      end

      def gauges(kind, types)
        kind_class = kind.to_s.singularize.camelize.constantize

        types.each do |type, opts|
          klass = kind_class.class_name_for_type(type).constantize
          metadata = { kind: kind, type: type, klass: klass, options: opts }
          gauge_types[kind][type] = metadata
          _gauge_getter(klass.name.underscore, metadata)
        end

        gauge_types
      end

      def metrics(*types)
        gauges(:metric, types)
      end

      def tops(*types)
        gauges(:top, types)
      end

      def gauge_types
        @gauge_types ||= Hash.new { |h, k| h[k] = {} }
      end

      def event_types
        @event_types ||= []
      end

      def _gauge_getter(name, metadata)
        klass = metadata[:klass]
        type = metadata[:type]
        options = metadata[:options]

        define_method(name) do |opts = {}|
          klass.new options.merge(opts).merge(type: type, namespace: self)
        end
      end
    end

    attr_reader :key, :event_types, :gauge_types, :event_ext

    def initialize(options = {})
      @key = options.fetch(:key) { self.class.key }
      @event_types = options.fetch(:event_types) { self.class.event_types }
      @gauge_types = options.fetch(:gauge_types) { self.class.gauge_types }
      @event_ext = options.fetch(:event_ext) { self.class.event_ext }
    end

    def events
      @events ||= begin
        events = event_types.map { |type| [type, Event.class_for(type).all] }
        events.map! { |type, klass| event_ext.call(type, klass) } if event_ext
        Hash[events]
      end
    end

    def events_between(period = nil)
      if period
        Hash[events.map { |type, klass| [type, klass.between(created_at: period)] }]
      else
        events
      end
    end

    def gauges
      Hash[gauge_types.map do |kind, types|
        [kind, Hash[types.map do |type, metadata|
          gauge = send(metadata[:klass].name.underscore)
          [type, gauge]
        end]]
      end]
    end
  end
end
