module Analyzing
  # Public: Adds support of gauges to Mongoid models.
  module Gaugeable
    extend ActiveSupport::Concern

    included do
      define_model_callbacks :refresh_gauges
    end

    # Internal: Generate a simple cache key for the object.
    def simple_cache_key
      "#{self.class.name.underscore}/#{id}"
    end

    # Internal: Get gauges for this instance.
    def gauges
      GaugeSet[self.class.gauges.map do |kind, types|
        [kind, GaugeSet[types.map do |type, metadata|
          gauge = send(metadata[:klass].name.underscore)
          [type, gauge]
        end]]
      end]
    end

    # Internal: Refresh gauges.
    def refresh_gauges
      run_callbacks(:refresh_gauges) do
        gauges.refresh
      end
    end

    module ClassMethods
      # Public: Add gauge to the gaugeable.
      #
      # kind    - The Symbol gauge kind.
      # types   - The Hash of gauge type -> default options.
      # options - The optional Hash of options:
      #           :kind_class_name - the String kind class name. If not passed,
      #                              kind_class_name would be reflected from
      #                              the name of kind.
      #
      # Examples
      #
      #   class Shop
      #     has_gauges :top, products: {}
      #   end
      def has_gauges(kind, types, options = {})
        if options.has_key?(:kind_class_name)
          kind_class = options[:kind_class_name].camelize.constantize
        else
          kind_class = kind.to_s.singularize.camelize.constantize
        end

        kind = kind.to_s.pluralize.to_sym
        types.each do |type, opts|
          klass = kind_class.class_name_for_type(type).constantize
          metadata = { kind: klass.kind, type: type, klass: klass, options: opts }
          gauges[kind][type] = metadata
          gauge_getter(klass.name.underscore, metadata)
        end
        subclasses.each { |sub| sub.has_gauges(kind, types) }
        gauges
      end
      alias_method :has_gauge, :has_gauges

      # Public: Add top to the gaugeable.
      def has_top(types)
        has_gauges(:top, types, kind_class_name: 'analyzing/top')
      end
      alias_method :has_tops, :has_top

      # Public: Add metric to the gaugeable.
      def has_metric(types)
        has_gauges(:metric, types, kind_class_name: 'analyzing/metric')
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

        define_method(name) do |period = nil, options = {}|
          options, period = period, nil if period.is_a?(Hash) && !options
          options.reverse_merge!(period: period) if period
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

    class GaugeSet < Hash
      def refresh
        values.each(&:refresh)
      end

      def to_json
        GaugeSet[map do |k, v|
          [k, v.to_json]
        end]
      end
    end
  end
end
