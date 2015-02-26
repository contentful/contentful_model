module ContentfulModel
  module Associations
    module BelongsTo
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # belongs_to is called on the child, and creates methods for mapping to the parent
        # @param classname [Symbol] the singular name of the parent
        def belongs_to(classname, *opts)
          raise ArgumentError, "belongs_to requires a class name as a symbol" unless classname.is_a?(Symbol)
          define_method "#{classname}" do
            #this is where we need to return the parent class
            self.instance_variable_get(:"@#{classname}")
          end

          define_method "#{classname}=" do |instance|
            #this is where we need to set the class name
            self.instance_variable_set(:"@#{classname}",instance)
          end
        end
      end
    end
  end
end