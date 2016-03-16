module ContentfulModel
  class Management < Contentful::Management::Client
    def initialize(options = {})
      super(ContentfulModel.configuration.management_token, options)
    end
  end
end
