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
      @errors ||= []
      unless self.respond_to?(:fields)
        @errors.push("Entity doesn't respond to the fields() method")
        return false
      end

      validations = self.class.send(:validations)
      unless validations.nil?
        validations.each do |type, fields|
          case type
            # validates_presence_of
            when :presence
              fields.each do |field|
                unless self.respond_to?(field)
                  @errors << "#{field} is required"
                end
              end
          end
        end
      end


      if @errors.empty?
        return true
      else
        return false
      end

    end

    module ClassMethods
      def validations
        @validations
      end
    end
  end
end