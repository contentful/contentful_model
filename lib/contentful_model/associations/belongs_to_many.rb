module ContentfulModel
  module Associations
    module BelongsToMany
      def self.included(base)
        base.extend ClassMethods
      end
      module ClassMethods
        #belongs_to_many is really the same as has_many but from the other end of the relationship.
        #Contentful doesn't store 2-way relationships so we need to call the API for the parent classname, and
        #iterate through it, finding this class. All the entries will be put in an array.
        # @param classnames [Symbol] plural name of the class we need to search through, to find this class
        def belongs_to_many(classnames, *opts)
          if self.respond_to?(:"@#{classnames}")
            self.send(classnames)
          else
            define_method "#{classnames}" do
              parents = self.instance_variable_get(:"@#{classnames}")
              if parents.nil?
                #get the parent class objects as an array
                parent_objects = classnames.to_s.singularize.classify.constantize.send(:all).send(:load)
                #iterate through parent objects and see if any of the children include the same ID as the method
                parents = parent_objects.select do |parent_object|
                  #check to see if the parent object responds to the plural or singular
                  if parent_object.respond_to?(:"#{self.class.to_s.pluralize.underscore}")
                    #if it responds to the plural, check if the ids in the collection include the id of this child
                    parent_object.send(:"#{self.class.to_s.pluralize.underscore}").collect(&:id).include?(self.id)
                  else
                    #if it doesn't respond to the plural, assume singular
                    parent_object.send(:"#{self.class.to_s.underscore}").id == self.id
                  end
                end
                self.instance_variable_set(:"@#{classnames}",parents)
              end
              parents
            end
          end
        end
      end
    end
  end
end