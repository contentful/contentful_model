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
        # has_many_nested :child_pages, root: -> { Page.find("some_id")}
        #
        # would setup up an instance attribute called parent_pages which lists all the direct
        # parents of this page. It would also create methods to find a page based on an array
        # of its ancestors, and generate an array of ancestors. Note that this builds an array of the
        # ancestors which called the object; because 'many' associations in Contentful are actually
        # 'belongs_to_many' from the child end, we might have several ancestors to a page. You will need
        # to write your own recursion for this, because it's probably an implementation-specific problem.
        def has_many_nested(association_name, options = {})
          has_many association_name, inverse_of: :"parent_#{self.to_s.underscore}"
          belongs_to_many :"parent_#{self.to_s.underscore.pluralize}", class_name: self.to_s, inverse_of: association_name
          if options[:root].is_a?(Proc)
            @root_method = options[:root]
          end

          # If there's a root method defined, set up a class method called root_[class name]. In our example this would be
          # Page.root_page.
          # @return [Object] the root entity returned from the proc defined in has_many_nested
          if defined?(@root_method) && @root_method.is_a?(Proc)
            # @return [Object] the root entity
            define_singleton_method :"root_#{self.to_s.underscore}" do
              @root_method.call
            end
          end

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
            find_ancestors.to_a.last
          end

          # @return [Boolean] whether or not this instance has children
          define_method :has_children? do
            !self.send(association_name).empty?
          end

          # @return [Array] a collection of child objects, based on the association name
          define_method :children do
            self.send(association_name)
          end

          # @return [Hash] a hash of nested child objects
          define_method :nested_children do
            self.children.inject({}) do |h,c|
              children = c.has_children? ? c.nested_children : nil
              h[c] = children
              h
            end
          end

          # Return a nested hash of children, returning the field specified
          # @param field [Symbol] the field you want to return, nested for each child
          # @return [Hash] of nested children, by that field
          define_method :nested_children_by do |field|
            self.children.inject({}) do |h,c|
              children = c.has_children? ? c.nested_children_by(field) : nil
              h[c.send(field)] = children
              h
            end
          end

          # Return a flattened hash of children by the specified field
          define_method :all_child_paths_by do |field, opts = {}|
            options = {prefix: nil}.merge!(opts)
            flatten_hash(nested_children_by(field)).keys.collect do |path|
              options[:prefix] ? path.unshift(options[:prefix]) : path
            end
          end

          # Search for a child by a certain field. This is called on the parent(s).
          # e.g. Page.root.find_child_path_by(:slug, "some-slug"). Accepts a prefix if you want to
          # prefix the children with the parent
          define_method :find_child_path_by do |field, value, opts = {}|
            all_child_paths_by(field,opts).select {|child| child.include?(value)}
          end

          # Private method to flatten a hash. Courtesy Cary Swoveland http://stackoverflow.com/a/23861946
          define_method :flatten_hash do |h,f=[],g={}|
            return g.update({ f=>h }) unless h.is_a? Hash
            h.each { |k,r| flatten_hash(r,f+[k],g) }
            g
          end
          self.send(:private, :flatten_hash)

        end
      end
    end
  end
end