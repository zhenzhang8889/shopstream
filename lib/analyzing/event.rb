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

      # Public: Track the event.
      def track(data = {})
        data = data.with_indifferent_access
        created_at = data.delete(:timestamp)
        attrs = { data: data }
        attrs.merge(created_at: created_at) if created_at

        scoped.create(attrs)
      end

      # Public: Define event's embedded data.
      def data(&block)
        embeds_one_inline(:data, autobuild: true, &block)
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
