# A module to validate entries. A little like ActiveRecord. We don't think this should be necessary, really,
# because Contentful should be doing the validating, but they expose invalid entries through the preview API.
module ContentfulModel
  module Validations
    def self.included(base)
      base.extend ClassMethods
      base.include Contentful::Validations::PresenceOf
      attr_reader :errors
    end

    def valid?
      validate
    end

    def invalid?
      !valid?
    end

    def validate
      @errors = []
      unless self.respond_to?(:fields)
        @errors.push("Entity doesn't respond to the fields() method")
        return false
      end

      validations = self.class.send(:validations)
      unless validations.nil?
        validations.each do |validation|
          @errors += validation.validate(self)
        end
      end

      @errors.empty?
    end

    module ClassMethods
      def validations
        @validations
      end
    end
  end
end
