module ContentfulModel
  module Associations
    # Defines Has Many association
    module HasMany
      def self.included(base)
        base.extend ClassMethods
      end

      # Class method
      module ClassMethods
        # has_many is called on the parent model
        #
        # e.g
        # class Foo
        #   has_many :bars, class_name: "Something"
        # end
        # The only reason for this method is that we might want to specify a relationship which is different
        # from the name of the model we're calling. If you specify a class_name, the method called on the parent will
        # be that. e.g. .somethings in this example
        # @param association_names [Symbol] the name of the child model, as a plural symbol
        # rubocop:disable Style/PredicateName
        def has_many(association_names, options = {})
          default_options = {
            class_name: association_names.to_s.singularize.classify,
            inverse_of: to_s.underscore.to_s
          }
          options = default_options.merge(options)

          include_discovered(options[:class_name])

          define_method association_names do
            begin
              # Start by calling the association name as a method on the superclass.
              # this will end up in ContentfulModel::Base#method_missing and return the value from Contentful.
              # We set the singular of the association name on each object in the collection to allow easy
              # reverse recursion without another API call (i.e. finding the Foo which called .bars())
              super().each do |child|
                child.send(:"#{options[:inverse_of]}=", self) if child.respond_to?(:"#{options[:inverse_of]}=")
              end
            rescue NoMethodError
              possible_field_name = options[:class_name].pluralize.underscore.to_sym
              return send(possible_field_name) if possible_field_name != association_names && respond_to?(possible_field_name)
              []
            end
          end
        end
        # rubocop:enable Style/PredicateName
      end
    end
  end
end
