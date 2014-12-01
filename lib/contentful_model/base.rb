module ContentfulModel
  class Base < Contentful::Entry
    include ContentfulModel::ChainableQueries

    def initialize(*args)
      super
      self.class.coercions ||= {}
      fields.each do |k,v|
        self.class.send(:attr_accessor, k)
        if self.class.coercions[k].nil?
          instance_variable_set(:"@#{k}", v)
        else
          instance_variable_set(:"@#{k}", self.class::COERCIONS[self.class.coercions[k]].call(v))
        end
      end
    end

    class << self
      attr_accessor :content_type_id, :coercions

      def client
        unless ContentfulModel.configuration.entry_mapping.has_key?(@content_type_id)
          ContentfulModel.configuration.entry_mapping[@content_type_id] = Object.const_get(self.to_s.to_sym)
        end

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