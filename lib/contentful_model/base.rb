require_relative 'associations/associations'
require_relative 'validations/validations'
require_relative 'manageable'
require_relative 'queries'
require_relative 'errors'
require_relative 'client'

module ContentfulModel
  class Base < Contentful::Entry
    include ContentfulModel::Associations
    include ContentfulModel::Validations
    include ContentfulModel::Manageable
    include ContentfulModel::Queries

    def initialize(*)
      super
      override_getters
    end

    def cache_key(*timestamp_names)
      if timestamp_names.present?
        raise ArgumentError, "ContentfulModel::Base models don't support named timestamps."
      end

      "#{self.class.to_s.underscore}/#{self.id}-#{self.updated_at.utc.to_s(:usec)}"
    end

    def hash
      "#{sys[:content_type].id}-#{sys[:id]}".hash
    end

    def eql?(other)
      super || other.instance_of?(self.class) && sys[:id].present? && other.sys[:id] == sys[:id]
    end

    private

    def override_getters
      sys.keys.each do |name|
        define_singleton_method name do
          self.class.coerce_value(name, sys[name])
        end
      end

      fields.keys.each do |name|
        define_singleton_method name do
          result = self.class.coerce_value(name, fields[name])

          if result.is_a?(Array)
            result.reject! { |r| r.is_a?(Contentful::Link) || (r.respond_to?(:invalid?) && r.invalid?) }
          elsif result.is_a?(Contentful::Link)
            result = nil
          elsif result.respond_to?(:fields) && result.send(:fields).empty?
            result = nil
          end

          if result.nil? && self.class.return_nil_for_empty_attribute_fields && self.class.return_nil_for_empty_attribute_fields.include?(name)
            return nil
          end

          result
        end
      end
    end

    def respond_to_missing?(method, private=false)
      if fields[:"#{method.to_s.camelize(:lower)}"].nil?
         super
      else
        true
      end
    end

    class << self
      attr_accessor :content_type_id, :coercions, :return_nil_for_empty_attribute_fields, :client

      def descendents
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def add_entry_mapping
        unless ContentfulModel.configuration.entry_mapping.has_key?(@content_type_id)
          ContentfulModel.configuration.entry_mapping[@content_type_id] = self.to_s.constantize
        end
      end

      def client
        # add an entry mapping for this content type
        self.add_entry_mapping
        if ContentfulModel.use_preview_api
          @preview_client ||= ContentfulModel::Client.new(ContentfulModel.configuration.to_hash)
        else
          @client ||= ContentfulModel::Client.new(ContentfulModel.configuration.to_hash)
        end
      end

      def content_type
        client.content_type(@content_type_id)
      end

      def coerce_field(*coercions)
        @coercions ||= {}
        coercions.each do |coercions_hash|
          @coercions.merge!(coercions_hash)
        end
        @coercions
      end

      def coerce_value(field_name, value)
        return value if coercions.nil?

        coercion = coercions[field_name]

        case coercion
        when Symbol, String
          coercion = Contentful::Field::KNOWN_TYPES[coercion.to_s]
          return coercion.new(value).coerce unless coercion.nil?
        when Proc
          coercion[value]
        else
          value
        end
      end

      def return_nil_for_empty(*fields)
        @return_nil_for_empty_attribute_fields ||= []

        fields.each do |field|
          define_method field do
            begin
              super
            rescue ContentfulModel::AttributeNotFoundError
              nil
            end
          end

          @return_nil_for_empty_attribute_fields.push(field)
        end
      end
    end
  end
end
