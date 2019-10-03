module ContentfulModel
  # Wrapper for the CMA Client
  class Management < Contentful::Management::Client
    def initialize(options = {})
      if options[:management_api]
        options.merge!(options[:management_api])
      end

      super(ContentfulModel.configuration.management_token, options)
    end
  end
end
