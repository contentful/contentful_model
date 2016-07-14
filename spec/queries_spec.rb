require 'spec_helper'

class MockQueriable
  include ContentfulModel::Queries
end

class MockQueriableEntry < MockQueriable
  def self.content_type_id
    'foo'
  end

  def self.client
    @@client ||= MockClient.new
  end

  def invalid?
    false
  end
end

describe ContentfulModel::Queries do
  subject { MockQueriableEntry }

  describe 'class methods' do
    it '::load' do
      response = [MockQueriableEntry.new, MockQueriableEntry.new]
      subject.client.response = response

      expect(subject.load).to eq response
    end

    it '::find' do
      response = [MockQueriableEntry.new, MockQueriableEntry.new]
      subject.client.response = response

      expect(subject.find('foo')).to eq response.first
    end
  end
end
