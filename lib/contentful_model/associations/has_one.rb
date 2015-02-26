module ContentfulModel
  module Associations
    module HasOne
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # has_one is called on the parent model, and sets a single instance var on the child
        # which is named the singular of the class this module is mixed into
        # it's conceptually identical to `has_many()`
        def has_one(classname, *opts)
          define_method "#{classname}" do
            if super().respond_to?(:"#{self.class.to_s.singularize.underscore}=")
              super().send(:"#{self.class.to_s.singularize.underscore}=",self)
            end
            super()
          end
        end
      end
    end
  end
end