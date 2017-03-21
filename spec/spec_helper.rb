require 'simplecov'
SimpleCov.start

require 'contentful_model'
require 'rspec'
require 'vcr'

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.ignore_localhost = true
  c.hook_into :webmock
  c.default_cassette_options = { record: :once }
end

def vcr(name, &block)
  VCR.use_cassette(name, &block)
end

class MockSpace
  attr_reader :id

  def initialize(id)
    @id = id
  end
end

def new_contentful_model
  klass = Class.new(ContentfulModel::Base) do
    self.content_type_id = 'ct_id'

    attr_reader :id, :space, :locale

    def initialize(id, space, fields = {})
      @locale = 'en-US'
      super('fields' => fields)
      @id = id
      @space = space
    end

    def fields(locale = default_locale)
      super || {}
    end
  end

  if block_given?
    klass.class_eval(&Proc.new)
  end

  klass
end

MockBase = new_contentful_model()

class MockClient
  attr_accessor :response

  def initialize(response = [])
    @response = response
  end

  def entries(query = {})
    response
  end
end
