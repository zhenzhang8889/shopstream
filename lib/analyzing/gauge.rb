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
  #     kind :top, position: :start
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
        if kind && name_kind_position
          regexp = name_kind_position == :start ? /^#{kind.to_s.camelize}/ : /#{kind.to_s.camelize}$/
        else
          regexp = //
        end

        name.demodulize.sub(regexp, '').underscore.to_sym
      end

      # Internal: Get/set the Symbol kind of the gauge.
      #
      # new_kind - The new Symbol kind of gauge.]
      # options  - The optional Hash:
      #            :position - the Symbol position of kind in class name.
      #            Equivalent to calling .name_kind_position separately.
      #
      # Examples
      #
      #   TopThings.kind :top
      #   TopThings.kind
      #   # => :top
      #
      #   AveragePurchaseMetric.kind
      #   # => :metric
      def kind(new_kind = nil, options = {})
        @kind ||= nil
        @kind = new_kind if new_kind
        name_kind_position options[:position] if options.has_key?(:position)
        @kind
      end

      # Internal: Get/set the position of gauge kind in the class name. It
      # is used to generate the type of gauge.
      #
      # Possible values are `:start` or `:end`.
      #
      # Examples
      #
      #   TopThings.name_kind_position :start
      #   TopThings.name_kind_position
      #   # => :start
      #   TopThings.type
      #   # => :things
      def name_kind_position(new_position = nil)
        @name_kind_position ||= nil
        @name_kind_position = new_position if new_position
        @name_kind_position
      end

      # Internal: Get the class name for gauge of this kind, with the
      # type specified.
      #
      # type - The Symbold type name.
      #
      # Returns the String class name.
      def class_name_for_type(type)
        if name_kind_position == :start
          "#{kind}_#{type}".camelize
        else
          "#{type}_#{kind}".camelize
        end
      end

      # When inheriting, we want to have kind & kind position in subclasses.
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@kind, kind)
        subclass.instance_variable_set(:@name_kind_position, name_kind_position)
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
      @period = object.send(@period) if @period.is_a?(Symbol)
      @period = object.instance_exec(&@period) if @period.respond_to?(:call)
      @options = options
    end

    # Public: Compute the gauge. If there is cached result already, it would be
    # returned. Requires specific gauge kinds to implement #_compute which would
    # compute and return the actual gauge value.
    def compute
      cached { cached(false) { _compute } }
    end

    # Public: Refresh the gauge. The gauge value will be force computed, even
    # if it's cached.
    def refresh
      cached(false) { force_cache { _compute } }
    end

    # Internal: When implementing own kind of gauges, you must redefine it to
    # perform needed calculations and return the result that will be cached.
    def _compute
      raise NotImplementedError, "You must redefine #_compute on your gauge kind."
    end

    # Public: Create a new instance of gauge with current options merged.
    def dup_for(new_options = {})
      self.class.new(options.merge(new_options))
    end

    # Public: Get associated events for the gauge period.
    #
    # Returns a Hash of event type -> event association.
    def events
      object.event_associations_between(period)
    end

    # Public: Get cache key for associated events.
    def events_cache_key
      stamps = events.values.map { |e| e.desc(:created_at).last.try(:created_at).to_i }
      "[#{stamps.join(',')}]"
    end

    # Internal: Fetch the cached value from cache store, execute block
    # otherwise.
    def cached(simple = true, &block)
      key = simple ? simple_cache_key : cache_key
      cache_store.fetch(key, expires_in: cache_expiry, &block)
    end

    # Internal: Execute the block and cache the result.
    def force_cache(simple = true, &block)
      key = simple ? simple_cache_key : cache_key
      cache_store.fetch(key, expires_in: cache_expiry, force: true, &block)
    end

    # Internal: Calculate the expirty term for cached value. Defaults to
    # difference between period end and start.
    def cache_expiry
      period.difference
    end

    # Internal: Generate a cache key for the gauge. Takes into account the type
    # and kind of the gauge, object class and id, period range, and dependent
    # events.
    def cache_key
      cache_key_components.join(':')
    end

    # Internal: Generate a cache key for the gauge. Takes into account the type
    # and kind of the gauge, object class and id, period range.
    def simple_cache_key
      simple_cache_key_components.join(':')
    end

    # Internal: Get simple cache key components.
    def simple_cache_key_components
      [self.class.kind,
       self.class.type,
       object.simple_cache_key,
       [period.begin.to_i, period.end.to_i].join('-')]
    end

    # Internal: Get cache key components.
    def cache_key_components
      simple_cache_key_components.append(events_cache_key)
    end

    # Internal: Get the cache store.
    def cache_store
      Rails.cache
    end

    # Public: Get JSON representation.
    def to_json
      compute
    end
  end
end
