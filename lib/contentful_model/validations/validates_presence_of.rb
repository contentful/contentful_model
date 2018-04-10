module Contentful
  module Validations
    # Module to check presence of a field
    module PresenceOf
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class method
      module ClassMethods
        def validates_presence_of(*args)
          @validations ||= []
          @validations << PresenceValidation.new(args)
        end
      end
    end

    # Actual validation
    class PresenceValidation
      attr_reader :fields

      def initialize(fields)
        @fields = fields
      end

      def validate(entry)
        errors = []

        fields.each do |field|
          errors << "#{field} is required" unless entry.respond_to?(field) && entry.public_send(field).present?
        end

        errors
      end
    end
  end
end
