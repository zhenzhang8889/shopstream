module Analyzing
  # Public: Makes the model eventful, i.e. provides options to declare which
  # events does the model support, and allows to query those events.
  #
  # Example
  #
  #   class Shop
  #     include Mongoid::Document
  #     include Analyzing::Eventful
  #
  #     has_events :requests
  #   end
  module Eventful
    extend ActiveSupport::Concern

    included do
      delegate :event_types, to: 'self.class'
      define_model_callbacks :track_event
      field :last_tracked_at, type: Time
    end

    # Internal: Get all event associations.
    #
    # Returns a Hash of event type -> event association.
    def event_associations
      Hash[event_types.map do |type|
        association = send(:"#{type}_events")
        [type.to_s.pluralize.to_sym, association]
      end]
    end

    # Internal: Get all event associations for given period.
    #
    # period - the time range.
    #
    # Returns a Hash of event type -> scoped event association.
    def event_associations_between(period)
      Hash[event_associations.map do |type, association|
        [type, association.between(created_at: period)]
      end]
    end

    module ClassMethods
      # Public: Declare event types for the model.
      #
      # Example
      #
      #   class MyModel
      #     include Mongoid::Document
      #     include Analyzing::Eventful
      #
      #     has_events :requests
      #   end
      def has_events(*events)
        @event_types ||= []
        events.map! { |type| type.to_s.singularize.to_sym }
        @event_types += events

        events.each do |type|
          has_many :"#{type}_events"
          event_tracker type
        end

        subclasses.each { |sub| sub.has_events(*events) }
        @event_types
      end

      # Internal: Get declared event types for the model.
      def event_types
        @event_types
      end

      # Internal: Define an event tracker method.
      #
      # event_type - The Symbol name of event type.
      # name       - The optional String or Symbol name of the method to
      #              define. If not passed, it will be constructed based on
      #              `event_type`.
      def event_tracker(event_type, name = nil)
        event_type = event_type.to_s.singularize.to_sym
        name ||= "track_#{event_type}"

        define_method(name) do |payload = {}|
          run_callbacks(:track_event) do
            event = event_associations[event_type.to_s.pluralize.to_sym].track(payload)
            set(:last_tracked_at, Time.now)
            try(:attempt_refresh_gauges)
            event
          end
        end
      end

      # When inheriting, we want to have supported event types in subclasses
      # as well.
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@event_types, @event_types)
      end
    end
  end
end
