module ContentfulModel
  module Associations
    module HasMany
      def self.included(base)
        base.extend ClassMethods
      end

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
        def has_many(association_names, options = {})
          default_options = {
            class_name: association_names.to_s.singularize.classify,
            inverse_of: self.to_s.underscore.to_s
          }
          options = default_options.merge(options)
          define_method association_names do
            begin
              # Start by calling the association name as a method on the superclass.
              # this will end up in ContentfulModel::Base#method_missing and return the value from Contentful.
              # We set the singular of the association name on each object in the collection to allow easy
              # reverse recursion without another API call (i.e. finding the Foo which called .bars())
              super().each do |child|
                child.send(:"#{options[:inverse_of]}=",self) if child.respond_to?(:"#{options[:inverse_of]}=")
              end
            rescue ContentfulModel::AttributeNotFoundError
              # If AttributeNotFoundError is raised, that means that the association name isn't available on the object.
              # We try to call the class name (pluralize) instead, or give up and return an empty collection
              possible_field_name = options[:class_name].pluralize.underscore.to_sym
              if possible_field_name != association_names && respond_to?(possible_field_name)
                self.send(possible_field_name)
              else
                #return an empty collection if the class name was the same as the association name and there's no attribute on the object.
                []
              end
            end
          end
        end
      end
    end
  end
end