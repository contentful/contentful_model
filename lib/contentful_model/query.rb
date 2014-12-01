module ContentfulModel
  class Query
    attr_accessor :parameters
    def initialize(reference_class, parameters=nil)
      @parameters = parameters || { 'content_type' => reference_class.content_type_id }
      @client = reference_class.client
    end

    def <<(parameters)
      @parameters.merge!(parameters)
    end

    def execute
      @client.entries(@parameters)
    end
  end
end