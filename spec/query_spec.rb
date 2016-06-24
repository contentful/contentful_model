require 'spec_helper'

class MockClient
  attr_accessor :response

  def initialize(response = [])
    @response = response
  end

  def entries(query = {})
    response
  end
end

class MockEntry
  attr_reader :client, :content_type_id

  def initialize(client, content_type_id, invalid = false)
    @client = client
    @content_type_id = content_type_id
    @invalid = invalid
  end

  def invalid?
    @invalid
  end
end

describe ContentfulModel::Query do
  let(:parameters) { { 'sys.id' => 'foo' } }
  let(:client) { MockClient.new }
  let(:entry) { MockEntry.new(client, 'foo_ct') }
  subject { described_class.new(entry, parameters) }

  describe 'attributes' do
    it ':parameters' do
      expect(subject.parameters).to eq parameters
    end
  end

  describe 'instance_methods' do
    it '#<< updates parameters' do
      expect(subject.parameters).to eq parameters

      subject << {foo: 'bar'}

      expect(subject.parameters).to eq parameters.merge(foo: 'bar')
    end

    it '#default_parameters' do
      expect(subject.default_parameters).to eq('content_type' => 'foo_ct')
    end

    it '#client' do
      expect(subject.client).to eq client
    end

    it '#reset' do
      subject << {'foo' => 'bar'}

      subject.reset

      expect(subject.parameters).to eq subject.default_parameters
    end

    it '#execute' do
      expect(subject.execute).to eq []

      client.response = [MockEntry.new(client, 'foo_ct', true)]

      expect(subject.execute).to eq []

      client.response = [entry]

      expect(subject.execute).to eq [entry]
    end
  end
end
