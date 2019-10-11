module ContentfulModel
  # Wrapper for the CMA Client
  class Management < Contentful::Management::Client
    def initialize(options = {})
      # Apply management specific options (if any)
      options = ContentfulModel.configuration.to_hash.merge(options)
      if config[:management_api]
        options = config.merge(config[:management_api])
      end

      super(ContentfulModel.configuration.management_token, options)
    end
  end
end
