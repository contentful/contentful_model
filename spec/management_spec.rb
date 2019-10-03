require 'spec_helper'

describe ContentfulModel::Management do
  before do
    ContentfulModel.configure do |c|
      c.management_token = 'foobar'
      c.options = {
        management_api: {
          timeout_read: 6
        },
        delivery_api: {
          timeout_read: 7
        }
      }
    end
  end

  it 'is a Contentful::Management::Client' do
    expect(subject).to be_a(Contentful::Management::Client)
  end

  it 'gets initialized with the configured management token' do
    expect(subject.access_token).to eq('foobar')
  end

  it 'gets initialized with the configured management specific timeout_read' do
    expect(subject.configuration[:timeout_read]).to eq(6)
  end
end
