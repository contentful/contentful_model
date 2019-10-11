require_relative 'errors'
require_relative 'management'

module ContentfulModel
  # Adds CMA functionality to Base
  module Manageable
    attr_reader :dirty

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(_item, _configuration = {}, localized = false, *)
      super
      @localized = localized
      @dirty = false
      @changed_fields = []
      define_setters
    end

    def to_management(entry_to_update = management_entry)
      published_entry = self.class.client.entry(id)
      fields.each do |field, value|
        entry_to_update.send(
          "#{field.to_s.underscore}=",
          management_field_value(
            @changed_fields.include?(field) ? value : published_entry.send(field.to_s.underscore)
          )
        )
      end

      entry_to_update
    end

    def refetch_management_entry
      @management_entry = fetch_management_entry
    end

    def save(skip_validations = false)
      return false if !skip_validations && invalid?(true)

      begin
        to_management.save
      rescue Contentful::Management::Conflict
        # Retries with re-fetched entry
        to_management(refetch_management_entry).save
      end

      @dirty = false
      @changed_fields = []

      self
    rescue Contentful::Management::Conflict
      raise(
        ContentfulModel::VersionMismatchError,
        'Version Mismatch persisting after refetch attempt, use :refetch_management_entry and try again later.'
      )
    end

    def save!
      save(true)
    end

    def publish
      begin
        to_management.publish
      rescue Contentful::Management::Conflict
        to_management(refetch_management_entry).save
      end

      self
    rescue Contentful::Management::Conflict
      raise(
        ContentfulModel::VersionMismatchError,
        'Version Mismatch persisting after refetch attempt, use :refetch_management_entry and try again later.'
      )
    end

    private

    def management_proxy
      @management_proxy ||= self.class.management.entries(
        space.id,
        ContentfulModel.configuration.environment
      )
    end

    def fetch_management_entry
      management_proxy.find(id)
    end

    def management_entry
      # Fetches always in case of Version changes to avoid Validation errors
      @management_entry ||= fetch_management_entry
    end

    def define_setters
      fields.each do |k, v|
        if @localized
          v.keys.each do |name|
            define_setter(name)
          end
        else
          define_setter(k)
        end
      end
    end

    def define_setter(name)
      define_singleton_method "#{name.to_s.underscore}=" do |value|
        @dirty = true
        @changed_fields << name
        fields[name] = value
      end
    end

    def management_field_value(entry_value)
      case entry_value
      when Contentful::Entry
        Contentful::Management::Entry.hash_with_link_object('Entry', entry_value)
      when Contentful::Asset
        Contentful::Management::Entry.hash_with_link_object('Asset', entry_value)
      when Contentful::Link
        Contentful::Management::Entry.hash_with_link_object(entry_value.sys[:link_type], entry_value)
      else
        entry_value
      end
    end

    # Management Class methods
    module ClassMethods
      def management(options = {})
        @management ||= ContentfulModel::Management.new(
          options.merge(raise_errors: true)
        )
      end

      def create(values = {}, publish = false)
        space = ContentfulModel.configuration.space
        environment = ContentfulModel.configuration.environment

        entry = management.entries(space, environment).create(
          management.content_types(space, environment).find(content_type_id),
          values
        )

        if publish
          entry.publish
          entry = find(entry.id)
        end

        entry
      end
    end
  end
end
