module ContentfulModel
  module Associations
    module HasManyNested
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
        # of its ancestors, and generate an array of ancestors. Note that this builds an array of the
        # ancestors which called the object; because 'many' associations in Contentful are actually
        # 'belongs_to_many' from the child end, we might have several ancestors to a page. You will need
        # to write your own recursion for this, because it's probably an implementation-specific problem.
        def has_many_nested(association_name)
          has_many association_name, inverse_of: :"parent_#{self.to_s.underscore}"
          belongs_to_many :"parent_#{self.to_s.underscore.pluralize}", class_name: self.to_s, inverse_of: association_name

          # A utility method which returns the parent object; saves passing around interpolated strings
          define_method :parent do
            self.send(:"parent_#{self.class.to_s.underscore}")
          end

          # Determine if the object has any parents. If it doesn't, it's considered a root.
          # This only works if the objects are called through their parents' 'child_[whatever]' method
          define_method :root? do
            parent.nil?
          end

          # Iterate over parents until you reach the root.
          # @param [Proc] a block to call on each ancestor
          # @return [Enumerable] which you can iterate over
          define_method :find_ancestors do |&block|
            return enum_for(:find_ancestors) unless block
            if parent.nil?
              #this *is* the parent
              return self
            end
            block.call(parent)
            unless parent && parent.root?
              parent.find_ancestors {|a| block.call(a)}
            end
          end

          # A utility method to return the results of `find_ancestors` as an array
          # @return [Array] of ancestors in reverse order (root last)
          define_method :ancestors do
            self.find_ancestors.to_a
          end

          # Return the last member of the enumerable, which is the root
          # @return the root instance of this object
          define_method :root do
            find_ancestors.last
          end

          # @return [Boolean] whether or not this instance has children
          define_method :has_children? do
            !self.send(association_name).empty?
          end

          # @return [Array] a collection of child objects, based on the association name
          define_method :children do
            self.send(association_name)
          end

        end
      end
    end
  end
end