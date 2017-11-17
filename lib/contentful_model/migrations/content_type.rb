module ContentfulModel
  module Migrations
    class ContentType
      def initialize(name = nil, management_content_type = nil)
        @name = name
        @management_content_type = management_content_type
      end

      def id(id)
        @id = id
      end

      def save
        if new?
          @management_content_type = management.content_types.create(
            ContentfulModel.configuration.space,
            id: @id || camel_case(@name),
            name: @name,
            fields: fields
          )
        else
          @management_content_type.fields = @fields
          @management_content_type.save
        end

        self
      end

      def publish
        return self if new?

        @management_content_type.publish

        self
      end

      def field(name, type)
        name = name.to_s
        type = type.to_s

        new_field = Contentful::Management::Field.new
        new_field.id = name.split(' ').map(&:capitalize).join('').underscore
        new_field.name = name
        new_field.type = management_type(type)
        new_field.link_type = management_link_type(type) if link?(type)
        new_field.items = management_items(type) if array?(type)

        fields << new_field

        new_field
      end

      def remove_field(field_id)
        @management_content_type.fields.destroy(field_id)
      end

      def new?
        @management_content_type.nil? || @management_content_type.id.nil?
      end

      def fields
        if new?
          return @fields ||= []
        else
          return @fields ||= fields_from_management_type
        end
      end

      private

      def camel_case(a_string)
        # Replace underscores
        a_string = a_string.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e.downcase : e.capitalize) }.join

        # Replace spaces
        a_string.split(' ').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e.downcase : e.capitalize) }.join
      end

      def fields_from_management_type
        @management_content_type.fields
      end

      def management_type(type)
        if [
          :text, :symbol,
          :integer, :number,
          :date, :boolean,
          :location, :object
        ].include?(type.to_sym)
          return type.capitalize
        elsif type == 'string'
          return 'Symbol'
        elsif link?(type)
          return 'Link'
        elsif array?(type)
          return 'Array'
        else
          raise_field_type_error(type)
        end
      end

      def management_link_type(type)
        if [:entry_link, :asset_link].include?(type.to_sym)
          return type.split('_').first.capitalize
        else
          raise_field_type_error(type)
        end
      end

      def management_items(type)
        if [:entry_array, :asset_array].include?(type.to_sym)
          items = Contentful::Management::Field.new
          items.type = 'Link'
          items.link_type = type.split('_').first.capitalize

          return items
        else
          raise_field_type_error(type)
        end
      end

      def link?(type)
        type.end_with?('_link')
      end

      def array?(type)
        type.end_with?('_array')
      end

      def management
        @management ||= ContentfulModel::Management.new
      end

      def raise_field_type_error(type)
        fail ContentfulModel::Migrations::InvalidFieldTypeError, "`:#{type}' is not a valid Field Type"
      end
    end
  end
end

