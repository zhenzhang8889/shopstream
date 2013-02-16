module Analyzing
  module Mongoid
    module InlineEmbeds
      extend ActiveSupport::Concern

      module ClassMethods
        # Public: Defines embeds_one relation inline.
        #
        # rel_name - The Symbol relation name. Embedded class name will be
        #            created based on it as well.
        # options  - The options Hash that will be proxied to "embeds_one".
        # block    - The body of the embedded class.
        #
        # Examples
        #
        #   class Post
        #     embeds_one_inline(:creator) do
        #       field :name
        #     end
        #   end
        def embeds_one_inline(rel_name, options = {}, &block)
          klass_name = rel_name.to_s.camelize
          embedded_class(klass_name, &block)

          embeds_one rel_name, options.reverse_merge(class_name: "#{name}::#{klass_name}", cascade_callbacks: true)
        end

        # Public: Defines embeds_many relation inline.
        #
        # rel_name - The Symbol relation name. Embedded class name will be
        #            created based on it as well.
        # options  - The options Hash that will be proxied to "embeds_many".
        # block    - The body of the embedded class.
        #
        # Examples
        #
        #   class Post
        #     embeds_many_inline(:comments) do
        #       field :comment
        #     end
        #   end
        def embeds_many_inline(rel_name, options = {}, &block)
          klass_name = rel_name.to_s.singularize.camelize
          embedded_class(klass_name, &block)

          embeds_many rel_name, options.reverse_merge(class_name: "#{name}::#{klass_name}", cascade_callbacks: true)
        end

        # Internal: Define a mongoid document inside current context.
        #
        # klass_name - The String constant name class will be assigned to.
        # block      - The body of the embedded class.
        def embedded_class(klass_name, &block)
          Class.new.tap do |klass|
            const_set(klass_name, klass)

            klass.send(:include, ::Mongoid::Document)
            klass.send(:include, InlineEmbeds)
            klass.embedded_in(:parent, class_name: name)
            klass.class_eval(&block) if block_given?
          end
        end
      end
    end
  end
end
