require_relative 'asset_dimensions'

module ContentfulModel
  # Module for providing querying capabilities to Asset
  class Asset < Contentful::Asset
    include ContentfulModel::AssetDimensions

    class << self
      def all(query = {})
        client.assets(query)
      end

      def find(id)
        client.asset(id)
      end

      def client
        if ContentfulModel.use_preview_api
          @preview_client ||= ContentfulModel::Client.new(
            ContentfulModel.configuration.to_hash
          )
        else
          @client ||= ContentfulModel::Client.new(
            ContentfulModel.configuration.to_hash
          )
        end
      end
    end
  end
end
