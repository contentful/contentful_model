module ContentfulModel
  class Base < Contentful::Entry
    include ContentfulModel::ChainableQueries
    include ContentfulModel::Associations

    def initialize(*args)
      super
      self.class.coercions ||= {}
    end

    #use method_missing to call fields on the model
    def method_missing(method, *args, &block)
      result = fields[:"#{method.to_s.camelize(:lower)}"]
      if result.nil?
        raise ContentfulModel::AttributeNotFoundError, "no attribute #{method} found"
      else
        # if there's no coercion specified, return the result
        if self.class.coercions[method].nil?
          return result

        #if there's a coercion specified for the field and it's a proc, pass the result
        #to the proc
        elsif self.class.coercions[method].is_a?(Proc)
          return self.class.coercions[method].call(result)
        #provided the coercion is in the COERCIONS constant, call the proc on that
        elsif !self.class::COERCIONS[self.class.coercions[method]].nil?
          return self.class::COERCIONS[self.class.coercions[method]].call(result)
        else
          #... or just return the result
          return result
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

      def coerce_field(*coercions)
        @coercions ||= {}
        coercions.each do |coercions_hash|
          @coercions.merge!(coercions_hash)
        end
        @coercions
      end

    end






  end
end