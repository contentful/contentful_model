module ContentfulModel
  # Wrapper for the CMA Client
  class Management < Contentful::Management::Client
    def initialize(options = {})
      # Apply management specific options (if any)
      config = ContentfulModel.configuration.to_hash
      if config[:management_api]
        options.merge!(config[:management_api])
      end

      super(ContentfulModel.configuration.management_token, options)
    end
  end
end
