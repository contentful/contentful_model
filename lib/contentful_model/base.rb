module ContentfulModel
  class Base < Contentful::Entry
    include ContentfulModel::ChainableQueries

    def initialize(*args)
      super
      self.class.coercions ||= {}
      fields.each do |k,v|
        field_name = k.to_s.underscore
        self.class.send(:attr_accessor, field_name)
        if self.class.coercions[k].nil?
          instance_variable_set(:"@#{field_name}", v)
        else
          instance_variable_set(:"@#{field_name}", self.class::COERCIONS[self.class.coercions[k]].call(v))
        end
      end
    end

    class << self
      attr_accessor :content_type_id, :coercions

      def inherited(subclass)
        unless ContentfulModel.configuration.entry_mapping.has_key?(@content_type_id)
          ContentfulModel.configuration.entry_mapping[@content_type_id] = Object.const_get(subclass.to_s.to_sym)
        end
      end

      def descendents
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def client
        @@client ||= Contentful::Client.new(ContentfulModel.configuration.to_hash)
      end

      def content_type
        client.content_type(@content_type_id)
      end

      def coerce_field(coercions_hash)
        self.coercions = coercions_hash
      end

    end






  end
end