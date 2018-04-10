module ContentfulModel
  module Associations
    # Defines Belongs To association
    module BelongsTo
      def self.included(base)
        base.extend ClassMethods
      end

      # Class method
      module ClassMethods
        # belongs_to is called on the child, and creates methods for mapping to the parent
        # @param _association_name [Symbol] the singular name of the parent
        def belongs_to(_association_name, _opts = {})
          fail(
            NotImplementedError,
            "Contentful doesn't have a singular belongs_to relationship. Use belongs_to_many instead."
          )
        end
      end
    end
  end
end
