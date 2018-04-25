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
        #   belongs_to_many :foos, class_name: Foo
        # end

        # In this example, children on the parent are accessed through an association called special_bars.

        # @param association_names [Symbol] plural name of the class we need to search through, to find this class
        # @param opts [true, Hash] options
        def belongs_to_many(association_names, opts = {})
          default_options = {
            class_name: association_names.to_s.singularize.classify,
            page_size: 100
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

          define_method association_names do
            parents = instance_variable_get(:"@#{association_names}")
            if parents.nil?
              parents = []
              options[:class_name].constantize.send(:each_entry, options[:page_size], 'sys.updatedAt', links_to_entry: id) do |parent|
                parents << parent
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
