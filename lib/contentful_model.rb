require 'require_all'
require 'contentful/management'
require 'contentful'
require_rel '.'

require "active_support/all"

module ContentfulModel
  class << self
    #accessor to set the preview API for use instead of the production one
    attr_accessor :use_preview_api

    #access the configuration class as ContentfulModel.configuration
    attr_accessor :configuration

    #block for configuration.
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end

  class Configuration
    attr_accessor :access_token,
                  :preview_access_token,
                  :space,
                  :entry_mapping,
                  :management_token,
                  :default_locale

    def initialize
      @entry_mapping ||= {}
    end

    #Rather than listing out all the possible attributes as setters, we have a catchall
    #called 'options' which takes a hash and generates instance vars
    #@param options [Hash]
    def options=(options)
      options.each do |k,v|
        instance_variable_set(:"@#{k}",v)
      end
    end


    # Return the Configuration object as a hash, with symbols as keys.
    # @return [Hash]
    def to_hash
      Hash[instance_variables.map { |name| [name.to_s.gsub("@","").to_sym, instance_variable_get(name)] } ]
    end
  end
end
