# A module to validate entries. A little like ActiveRecord. We don't think this should be necessary, really,
# because Contentful should be doing the validating, but they expose invalid entries through the preview API.
module ContentfulModel
  module Validations
    def self.included(base)
      base.extend ClassMethods
      base.include Contentful::Validations::PresenceOf
      attr_reader :errors
    end

    def valid?(save = false)
      validate(save)
    end

    def invalid?(save = false)
      !valid?(save)
    end

    def validate(save = false)
      @errors = []
      unless self.respond_to?(:fields)
        @errors.push("Entity doesn't respond to the fields() method")
        return false
      end

      validation_kinds = [:validations]
      validation_kinds << :save_validations if save

      validation_kinds.each do |validation_kind|
        validations = self.class.send(validation_kind)
        unless validations.nil?
          validations.each do |validation|
            @errors += validation.validate(self)
          end
        end
      end

      @errors.empty?
    end

    module ClassMethods
      def validations
        @validations
      end

      def save_validations
        @save_validations
      end

      def validate_with(validation, on_load: false)
        if validation.is_a?(Class)
          validation = validation.new
        elsif validation.respond_to?(:validate)
          validation = validation
        else
          fail '::validate_with requires a Class or object that responds to #validate(entry)'
        end

        if on_load
          @validations ||= []
          @validations << validation
        else
          @save_validations ||= []
          @save_validations << validation
        end
      end

      def validate(name, fn = nil, on_load: false, &block)
        vs = []
        fail '::validate requires either a function or a block sent as a validation' if fn.nil? && block.nil?

        vs << ::Contentful::Validations::LambdaValidation.new(name, fn) unless fn.nil?
        vs << ::Contentful::Validations::LambdaValidation.new(name, block) unless block.nil?

        if on_load
          @validations ||= []
          @validations += vs
        else
          @save_validations ||= []
          @save_validations += vs
        end
      end
    end
  end
end
