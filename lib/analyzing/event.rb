module Analyzing
  # Public: Event, the integral part of the tracking system. Consists of a
  # created_at timestamp, associated model, and data payload.
  #
  # Examples
  #
  #   class LoadEvent
  #     include Analyzing::Event
  #     event_for :page
  #   end
  module Event
    extend ActiveSupport::Concern

    included do
      include ::Mongoid::Document
      include ::Mongoid::Timestamps::Created
      include Analyzing::Mongoid::InlineEmbeds

      index(created_at: -1)
    end

    module ClassMethods
      # Public: Declare which model is associated with this event.
      def event_for(model)
        belongs_to model
      end

      # Internal: Get the event type.
      #
      # Examples
      #
      #   LoadEvent.type
      #   # => :load
      def type
        name.sub(/Event$/, '').underscore.to_sym
      end
    end
  end
end
