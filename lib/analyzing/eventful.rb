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
    end

    # Internal: Get all event associations.
    #
    # Returns a Hash of event type -> event association.
    def event_associations
      Hash[event_types.map do |type|
        association = send(:"#{type}_events")
        [type, association]
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
        events.each { |type| has_many :"#{type}_events" }
        subclasses.each { |sub| sub.has_events(*events) }
        @event_types
      end

      # Internal: Get declared event types for the model.
      def event_types
        @event_types
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
