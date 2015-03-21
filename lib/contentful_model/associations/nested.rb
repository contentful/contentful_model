module ContentfulModel
  module Associations
    module Nested
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # has_many_nested allows you to set up a tree relationship
        # it calls has_many and belongs_to_many on the class, and sets up
        # some methods to find a deeply-nested instance's parents
        #
        # To set this up in contentful, add a multi-entry field validated to the same model
        # as the parent, and give it a name. For example, Page might have a field called childPages:
        #
        # has_many_nested :child_pages
        #
        # would setup up an instance attribute called parent_pages which lists all the direct
        # parents of this page. It would also create methods to find a page based on an array
        # of its ancestors, and generate an array of ancestors (an expensive API call)
        def has_many_nested(association_name)
          has_many association_name, inverse_of: :"parent_#{self.to_s.underscore}"
          belongs_to_many :"parent_#{self.to_s.underscore.pluralize}", class_name: self.to_s, inverse_of: association_name
        end

      end
    end
  end
end