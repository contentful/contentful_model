require_relative 'associations/associations'
require_relative 'validations/validations'
require_relative 'manageable'
require_relative 'queries'
require_relative 'errors'
require_relative 'client'

module ContentfulModel
  # Wrapper for Contentful::Entry which provides ActiveModel-like syntax
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
      fail ArgumentError, "ContentfulModel::Base models don't support named timestamps." if timestamp_names.present?

      "#{self.class.to_s.underscore}/#{id}-#{updated_at.utc.to_s(:usec)}"
    end

    def hash
      "#{sys[:content_type].id}-#{sys[:id]}".hash
    end

    def eql?(other)
      super || other.instance_of?(self.class) && sys[:id].present? && other.sys[:id] == sys[:id]
    end

    private

    def define_sys_methods
      sys.keys.each do |name|
        define_singleton_method name do
          self.class.coerce_value(name, sys[name])
        end
      end
    end

    def filter_invalids(value)
      return value.reject { |v| v.is_a?(Contentful::Link) || (v.respond_to?(:invalid?) && v.invalid?) } if value.is_a?(Array)
      return nil if value.is_a?(Contentful::Link) || value.respond_to?(:fields) && value.fields.empty?

      value
    end

    def nillable?(name, value)
      value.nil? &&
        self.class.return_nil_for_empty_attribute_fields &&
        self.class.return_nil_for_empty_attribute_fields.include?(name)
    end

    def define_fields_methods
      fields.keys.each do |name|
        define_singleton_method name do
          result = filter_invalids(
            self.class.coerce_value(name, fields[name])
          )

          return nil if nillable?(name, result)

          result
        end
      end
    end

    def override_getters
      define_sys_methods
      define_fields_methods
    end

    def respond_to_missing?(method, private = false)
      return super if fields[:"#{method.to_s.camelize(:lower)}"].nil?
      true
    end

    class << self
      attr_accessor :content_type_id, :coercions, :return_nil_for_empty_attribute_fields, :client

      def descendents
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def discovered_includes
        @discovered_includes ||= []
      end

      def discovered_include_level
        @discovered_include_level ||= nil
        return @discovered_include_level unless @discovered_include_level.nil?

        includes = {}
        discovered_includes.each do |klass|
          includes[klass] = klass.constantize.discovered_includes.reject { |i| i == to_s } + [klass]
        end

        include_level = includes.values.map(&:size).max
        return @discovered_include_level = 1 if include_level.nil? || include_level.zero?
        return @discovered_include_level = 10 if include_level >= 10
        @discovered_include_level = include_level + 1
      end

      def include_discovered(klass)
        discovered_includes << klass unless discovered_includes.include?(klass)
      end

      def mapping?
        ContentfulModel.configuration.entry_mapping.key?(@content_type_id)
      end

      def add_entry_mapping
        ContentfulModel.configuration.entry_mapping[@content_type_id] = to_s.constantize unless mapping?
      end

      def client
        # add an entry mapping for this content type
        add_entry_mapping
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
            result = super
            result.present? ? result : nil
          end

          @return_nil_for_empty_attribute_fields.push(field)
        end
      end
    end
  end
end
