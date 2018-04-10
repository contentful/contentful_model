module ContentfulModel
  module Associations
    # Defines Belongs To Many association
    module BelongsToMany
      def self.included(base)
        base.extend ClassMethods
      end

      # Class method
      module ClassMethods
        # belongs_to_many implements a has_many association from the opposite end, and allows a call to the association name
        # to return all instances for which this object is a child.
        #
        # It's moderately expensive because we have to iterate over every parent, checking whether this instance
        # is in the children. It requires one API call.

        # class Bar
        #   belongs_to_many :foos, class_name: Foo, inverse_of: :special_bars
        # end

        # In this example, children on the parent are accessed through an association called special_bars.

        # @param association_names [Symbol] plural name of the class we need to search through, to find this class
        # @param opts [true, Hash] options
        def belongs_to_many(association_names, opts = {})
          default_options = {
            class_name: association_names.to_s.singularize.classify,
            inverse_of: to_s.underscore.to_sym
          }
          options = default_options.merge(opts)

          # Set up the association name for the instance which loaded this object
          # This is useful in situations where, primarily, it's a 1:* relationship (i.e. belongs_to)
          # even though this isn't actually supported by Contentful
          #
          # f = Foo.first
          # b = f.bars.first
          # b.foo #would return the instance of Foo which loaded it

          define_method association_names.to_s.singularize do
            instance_variable_get(:"@#{association_names.to_s.singularize}")
          end

          define_method "#{association_names.to_s.singularize}=" do |parent|
            instance_variable_set(:"@#{association_names.to_s.singularize}", parent)
            instance_variable_set(:@loaded_with_parent, true)
            self
          end

          define_method :loaded_with_parent? do
            instance_variable_get(:@loaded_with_parent) ? true : false
          end

          # Set up the association name (plural)
          return send(association_names) if respond_to?(association_names)

          define_method association_names do
            parents = instance_variable_get(:"@#{association_names}")
            if parents.nil?
              # get the parent class objects as an array
              parent_objects = options[:class_name].constantize.send(:all).send(:load)

              # iterate through parent objects and see if any of the children include the same ID as the method
              parents = parent_objects.select do |parent_object|
                # check to see if the parent object responds to the plural or singular.
                if parent_object.respond_to?(:"#{options[:inverse_of].to_s.pluralize}")
                  collection_of_children_on_parent = parent_object.send(:"#{options[:inverse_of].to_s.pluralize}")

                  # get the collection of children from the parent. This *might* be nil if the parent doesn't have
                  # any children, in which case, just skip over this parent item and move on to the next.
                  next if collection_of_children_on_parent.nil?

                  collection_of_children_on_parent.collect(&:id).include?(id)
                else
                  # if it doesn't respond to the plural, assume singular
                  child_on_parent = parent_object.send(:"#{options[:inverse_of]}")

                  # Do the same skipping routine on nil.
                  next if child_on_parent.nil?

                  child_on_parent.send(:id) == id
                end
              end
              instance_variable_set(:"@#{association_names}", parents)
            end
            parents
          end
        end
      end
    end
  end
end
