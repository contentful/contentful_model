module ContentfulModel
  module Migrations
    module ContentTypeFactory
      def self.create(name, fields = {}, &block)
        content_type = ContentfulModel::Migrations::ContentType.new(name)

        yield(content_type) if block_given?

        fields.each do |field_name, type|
          content_type.field(field_name, type)
        end

        content_type.save
      end

      def self.find(content_type_id)
        ContentfulModel::Migrations::ContentType.new(
          nil,
          ContentfulModel::Management.new.content_types.find(
            ContentfulModel.configuration.space,
            content_type_id
          )
        )
      end
    end
  end
end
