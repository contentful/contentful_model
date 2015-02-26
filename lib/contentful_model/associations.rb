# A module to map relationships, a little like ActiveRecord::Relation
# This is necessary because Contentful::Link classes are not 2-way, so you can't
# get the parent from a child.
module ContentfulModel
  module Associations
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