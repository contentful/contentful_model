module ContentfulModel
  class Query
    attr_accessor :parameters
    def initialize(referenced_class, parameters=nil)
      @parameters = parameters || {}
      @referenced_class = referenced_class
    end

    def <<(parameters)
      @parameters.merge!(parameters)
    end

    def default_parameters
      { 'content_type' => @referenced_class.send(:content_type_id) }
    end

    def execute
      query = @parameters.merge(default_parameters)
      result = client.send(:entries,query)
      result.items.reject! { |entity| entity.is_a?(Contentful::Link) || entity.invalid? }
      result
    end

    def client
      @client ||= @referenced_class.send(:client)
    end

    def reset
      @parameters = default_parameters
    end
  end
end
