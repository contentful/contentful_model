module ContentfulModel
  module Associations
    module HasMany
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # has_many is called on the parent model, and sets an instance var on the child
        # which is named the plural of the class this module is mixed into.
        #
        # e.g
        # class Foo
        #   has_many :bars
        # end
        # TODO this breaks down in situations where the has_many end doesn't respond to bars because the association is really the other way around
        # @param classname [Symbol] the name of the child model, as a plural symbol
        def has_many(classname, *opts)
          #define an instance method called the same as the arg passed in
          #e.g. bars()
          define_method "#{classname}" do
            # call bars() on super, and for each, call bar=(self)
            super().collect do |instance|
              instance.send(:"#{self.class.to_s.singularize.underscore}=",self)
              #return the instance to the collect() method
              instance
            end
          end
        end
      end
    end
  end
end