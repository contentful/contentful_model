require 'contentful_model'
require 'rspec'
require 'vcr'

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

class MockBase < ContentfulModel::Base
  self.content_type_id = 'ct_id'

  attr_reader :id, :fields, :space, :locale

  def initialize(id, space, fields = {})
    @locale = 'en-US'
    super('fields' => fields)
    @id = id
    @space = space
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
