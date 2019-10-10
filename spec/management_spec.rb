require 'spec_helper'

describe ContentfulModel::Management do
  before do
    ContentfulModel.configure do |c|
      c.management_token = 'foobar'
      c.options = {
        timeout_connect: 2,
        timeout_read: 5,
        timeout_write: 19,

        management_api: {
          timeout_connect: 3,
          timeout_read: 6,
          timeout_write: 20
        },
        delivery_api: {
          timeout_connect: 4,
          timeout_read: 7,
          timeout_write: 21
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
