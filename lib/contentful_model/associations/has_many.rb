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
            class_name: association_names.to_s.singularize.classify
          }
          options = default_options.merge(options)
          define_method association_names do
            begin
              # try calling the association name directly on the superclass - will be picked up by
              # ContentfulModel::Base#method_missing and return a value if there is one for the attribute
              super()
            rescue ContentfulModel::AttributeNotFoundError
              # If AttributeNotFoundError is raised, that means that the association name isn't available on the object.
              # We try to call the class name (pluralize) instead, or give up and return an empty collection
              if options[:class_name].pluralize.underscore.to_sym != association_names
                self.send(options[:class_name].pluralize.underscore.to_sym)
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