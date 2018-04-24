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

class MockClient
  attr_accessor :response

  def initialize(response = [])
    @response = response
  end

  def entries(query = {})
    response
  end
end

class Cat < ContentfulModel::Base
  self.content_type_id = 'cat'
end

class CoercedCat < ContentfulModel::Base
  self.content_type_id = 'cat'

  coerce_field name: -> (name) { name.gsub('Nyan', 'Fat') }
  coerce_field created_at: 'String'
  coerce_field updated_at: 'Date'
end

class TestModel < ContentfulModel::Base
  self.content_type_id = 'testModel'
end
