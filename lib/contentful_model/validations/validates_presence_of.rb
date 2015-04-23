module Contentful
  module Validations
    module PresenceOf
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def validates_presence_of(*args)
          @validations ||= {}
          @validations[:presence] ||= []
          @validations[:presence].push(args)
          @validations[:presence].flatten!
        end
      end
    end
  end
end