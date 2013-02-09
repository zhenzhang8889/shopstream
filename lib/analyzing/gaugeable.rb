module Analyzing
  # Public: Adds support of gauges to Mongoid models.
  module Gaugeable
    extend ActiveSupport::Concern

    # Internal: Generate a simple cache key for the object.
    def simple_cache_key
      "#{self.class.name.underscore}/#{id}"
    end

    # Internal: Get gauges for this instance.
    def gauges
      Hash[self.class.gauges.map do |kind, types|
        [kind, Hash[types.map do |type, metadata|
          gauge = send(metadata[:klass].name.underscore)
          [type, gauge]
        end]]
      end]
    end

    module ClassMethods
      # Public: Add gauge to the gaugeable.
      #
      # kind  - The Symbol gauge kind.
      # types - The Hash of gauge type -> default options.
      #
      # Examples
      #
      #   class Shop
      #     has_gauges :top, products: {}
      #   end
      def has_gauges(kind, types)
        kind_class = kind.to_s.singularize.camelize.constantize
        kind = kind.to_s.pluralize.to_sym
        types.each do |type, options|
          klass = kind_class.class_name_for_type(type).constantize
          metadata = { kind: kind.to_s.singularize.to_sym, type: type, klass: klass, options: options }
          gauges[kind][type] = metadata
          gauge_getter(klass.name.underscore, metadata)
        end
        subclasses.each { |sub| sub.has_gauges(kind, types) }
        gauges
      end
      alias_method :has_gauge, :has_gauges

      # Public: Add top to the gaugeable.
      def has_top(types)
        has_gauges(:top, types)
      end
      alias_method :has_tops, :has_top

      # Public: Add metric to the gaugeable.
      def has_metric(types)
        has_gauges(:metric, types)
      end
      alias_method :has_metrics, :has_metric

      # Internal: Get gauges metadata.
      def gauges
        @gauges ||= Hash.new { |h, k| h[k] = {} }
      end

      # Internal: Define a getter for the gauge.
      #
      # name     - The String or Symbol name of method to define.
      # metadata - The Hash of gauge metadata.
      def gauge_getter(name, metadata)
        klass = metadata[:klass]

        define_method(name) do |period, options = {}|
          options.reverse_merge!(period: period)
          options.reverse_merge!(metadata[:options])
          klass.new options.merge(object: self)
        end
      end

      # When inheriting, we want to have supported gauges in subclasses.
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@gauges, @gauges)
      end
    end
  end
end
