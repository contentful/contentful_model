module ContentfulModel
  module Manageable
    def initialize(*args)
      super

      @dirty = false
      define_setters
    end

    def to_management
      update_management_entry_fields(management_entry)
    end

    protected

    def update_management_entry_fields(management_entry)
      map_management_fields(management_entry, fields)
    end

    private

    def management_space
      @management_space ||= self.class.management(default_locale: locale).spaces.find(space.id)
    end

    def management_entry
      # Fetches always in case of Version changes to avoid Validation errors
      management_space.entries.find(id)
    end

    def define_setters
      fields.keys.each do |f|
        define_singleton_method "#{f.to_s.underscore}=" do |value|
          @dirty = true
          fields[f] = value
        end
      end
    end

    def map_management_fields(management_entry, fields)
      fields.each do |field, value|
        management_entry.send(
          "#{field.to_s.underscore}=",
          management_field_value(value)
        )
      end

      management_entry
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
