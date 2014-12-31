module ContentfulModel
  class Base < Contentful::Entry
    include ContentfulModel::ChainableQueries

    def initialize(*args)
      super
      self.class.coercions ||= {}
    end

    #use method_missing to call fields on the model
    def method_missing(method)
      result = fields[:"#{method}"]
      if result.nil?
        raise NoMethodError, "No method or attribute #{method} for #{self}"
      else
        if self.class.coercions[method].nil?
          return result
        else
          return self.class::COERCIONS[self.class.coercions[method]].call(result)
        end
      end
    end

    def cache_key(*timestamp_names)
      if timestamp_names.present?
        raise ArgumentError, "ContentfulModel::Base models don't support named timestamps."
      end

      "#{self.class.to_s.underscore}/#{self.id}-#{self.updated_at.utc.to_s(:number)}"

    end

    def save
      raise NotImplementedError, "Saving models isn't implemented; we need to use the Contentful Management API for that. Pull requests welcome!"
    end

    alias_method :create, :save

    class << self
      attr_accessor :content_type_id, :coercions

      def descendents
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def add_entry_mapping
        unless ContentfulModel.configuration.entry_mapping.has_key?(@content_type_id)
          ContentfulModel.configuration.entry_mapping[@content_type_id] = Object.const_get(self.to_s.to_sym)
        end
      end

      def client
        self.add_entry_mapping
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