module Analyzing
  # Internal: A generic gauge class. You are not expected to use it directly, but
  # rather subclass it yourself or use already-implemented gauges.
  #
  # You also should define the `.kind` method that would return a Symbol
  # gauge type. Example gauge types are `:top`, `:metric`.
  #
  # Kind of the gauge tells about some generic implementation of the gauge,
  # e.g. a top or a metric. Type, on another hand, tells about specific
  # implementation of the gauge, e.g. top articles, purchases metric, and so on.
  # In other words, every gauge can be identified by two measures - kind and
  # type.
  #
  # Examples
  #
  #   # Define a new kind of gauge
  #   class Top < Analyzing::Gauge
  #     def kind
  #       :top
  #     end
  #
  #     def class_name_kind
  #       :start
  #     end
  #   end
  #
  #   # Define a new type of gauge
  #   class TopThings < Top
  #   end
  class Gauge
    # Public: Getters for object, period & options the gauge was instantiated
    # with.
    attr_reader :object, :period, :options

    class << self
      # Internal: Get the Symbol type of the gauge. It excludes the kind of
      # gauge from the name of gauge.
      #
      # Examples
      #
      #   TopThings.type
      #   # => :things
      #
      #   AveragePurchaseMetric.type
      #   # => :average_purchase
      def type
        regexp = class_name_kind == :start ? /^#{kind.to_s.camelize}/ : /#{kind.to_s.camelize}$/
        name.demodulize.sub(regexp, '').underscore.to_sym
      end

      # Internal: Get the Symbol kind of the gauge. Override this method for
      # every new kind of gauges you create.
      #
      # Examples
      #
      #   TopThings.kind
      #   # => :top
      #
      #   AveragePurchaseMetric.kind
      #   # => :metric
      def kind
        raise NotImplementedError, '.kind not implemented'
      end

      # Internal: Get the position of gauge kind in the class name. It
      # is used to generate the type of gauge. Override this method for
      # every new kind of gauges you create.
      #
      # Possible return values are `:start` or `:end`.
      #
      # Examples
      #
      #   TopThings.class_name_kind
      #   # => :start
      #   TopThings.type
      #   # => :things
      def class_name_kind
        raise NotImplementedError, '.class_name_kind not implemented'
      end
    end

    # Public: Initialize a gauge.
    #
    # options - The options Hash:
    #           :object - the object to make gauge for.
    #           :period - the Time range for the gauge.
    def initialize(options = {})
      @object = options[:object]
      @period = options[:period]
      @options = options
    end

    # Internal: Fetch the cached value from cache store, execute block
    # otherwise.
    def cached(&block)
      cache_store.fetch(cache_key, expires_in: cache_expiry, &block)
    end

    # Internal: Calculate the expirty term for cached value. Defaults to
    # difference between period end and start.
    def cache_expiry
      period.end.to_i - period.begin.to_i
    end

    # Internal: Generate a cache key for the gauge. Takes into account the type
    # and kind of the gauge, object class and id, period range. Feel free to
    # redefine it if you feel like adding additional caching dependencies. The
    # original version would still be available at `#simple_cache_key`.
    def cache_key
      [self.class.kind,
       self.class.type,
       object.simple_cache_key,
       [period.begin.to_i, period.end.to_i].join('-')
      ].join(':')
    end
    alias_method :simple_cache_key, :cache_key

    # Internal: Get the cache store.
    def cache_store
      Rails.cache
    end
  end
end
