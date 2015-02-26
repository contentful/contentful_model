module ContentfulModel
  module Associations
    module HasOne
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        #has_one defines a method on the parent which wraps around the superclass's implementation. In most cases this
        #will end up at ContentfulModel::Base#method_missing and look at the fields on a content object.
        #We wrap around it like this so we can specify a class_name option to call a different method from the association
        #name.
        # class Foo
        #   has_one :special_bar, class_name: "Bar"
        # end
        # @param association_name [Symbol] the name of the association. In this case Foo.special_bar.
        # @param options [Hash] a hash, the only key of which is important is class_name.
        def has_one(association_name, options = {})
          default_options = {
            class_name: association_name.to_s.classify,
            inverse_of: self.to_s.underscore.to_sym
          }
          options = default_options.merge(options)
          # Define a method which matches the association name
          define_method association_name do
            begin
              # Start by calling the association name as a method on the superclass.
              # this will end up in ContentfulModel::Base#method_missing and return the value from Contentful.
              # We set the singular of the association name on this object to allow easy recursing.
              super().send(:"#{options[:inverse_of]}=",self)
            rescue ContentfulModel::AttributeNotFoundError
              # If method_missing returns an error, the field doesn't exist. If a class is specified, try that.
              if options[:class_name].underscore.to_sym != association_name
                self.send(options[:class_name].underscore.to_sym)
              else
                #otherwise give up and return nil
                nil
              end
            end
          end
        end
      end
    end
  end
end