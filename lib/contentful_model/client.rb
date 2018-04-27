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
      super({
        raise_errors: true,
        dynamic_entries: :auto,
        integration_name: 'contentful_model',
        integration_version: ::ContentfulModel::VERSION
      }.merge(configuration))
    end
  end
end
