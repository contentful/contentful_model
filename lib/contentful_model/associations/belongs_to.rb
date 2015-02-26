module ContentfulModel
  module Associations
    module BelongsTo
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # belongs_to is called on the child, and creates methods for mapping to the parent
        # @param association_name [Symbol] the singular name of the parent
        def belongs_to(association_name, opts = {})
          raise NotImplementedError, "Contentful doesn't have a singular belongs_to relationship. Use belongs_to_many instead."
        end
      end
    end
  end
end