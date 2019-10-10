require_relative 'asset'

module ContentfulModel
  # Wrapper for the CDA Client
  class Client < Contentful::Client
    PREVIEW_API_URL = 'preview.contentful.com'.freeze

    def initialize(configuration)
      configuration[:resource_mapping] = configuration.fetch(:resource_mapping, {}).merge(
        'Asset' => ContentfulModel::Asset
      )

      if ContentfulModel.use_preview_api
        configuration[:api_url] = PREVIEW_API_URL
        configuration[:access_token] = configuration[:preview_access_token]
      end

      configuration = {
        raise_errors: true,
        dynamic_entries: :auto,
        integration_name: 'contentful_model',
        integration_version: ::ContentfulModel::VERSION,
        raise_for_empty_fields: false
      }.merge(configuration)

      # Apply delivery specific options (if any)
      if configuration[:delivery_api]
        configuration.merge!(configuration[:delivery_api])
      end

      super(configuration)
    end
  end
end
