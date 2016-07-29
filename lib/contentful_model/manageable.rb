module ContentfulModel
  module Manageable
    attr_reader :dirty

    def initialize(*args)
      super
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

    def save
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
      fail ContentfulModel::VersionMismatchError, "Version Mismatch persisting after refetch attempt, use :refetch_management_entry and try again later."
    end

    def publish
      begin
        to_management.publish
      rescue Contentful::Management::Conflict
        to_management(refetch_management_entry).save
      end

      self
    rescue Contentful::Management::Conflict
      fail ContentfulModel::VersionMismatchError, "Version Mismatch persisting after refetch attempt, use :refetch_management_entry and try again later."
    end

    private

    def management_space
      @management_space ||= self.class.management(default_locale: locale).spaces.find(space.id)
    end

    def fetch_management_entry
      management_space.entries.find(id)
    end

    def management_entry
      # Fetches always in case of Version changes to avoid Validation errors
      @management_entry ||= fetch_management_entry
    end

    def define_setters
      fields.each do |k, v|
        if Contentful::Constants::KNOWN_LOCALES.include?(k.to_s)
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
        fields(default_locale)[name] = value
      end
    end

    def management_field_value(entry_value)
      case entry_value
      when Contentful::Entry
        Contentful::Management::Entry.hash_with_link_object('Entry', entry_value)
      when Contentful::Asset
        Contentful::Management::Entry.hash_with_link_object('Asset', entry_value)
      when Contentful::Link
        Contentful::Management::Entry.hash_with_link_object(entry_value.sys[:contentType], entry_value)
      else
        entry_value
      end
    end

    module ClassMethods
      def management(options = {})
        @management ||= ContentfulModel::Management.new(
          options.merge(default_locale: ContentfulModel.configuration.default_locale)
        )
      end

      def create(values = {}, publish = false)
        entry = management.entries.create(
          management.content_types.find(
            ContentfulModel.configuration.space,
            content_type_id
          ),
          values
        )

        if publish
          entry.publish
          entry = self.find(entry.id)
        end

        entry
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
