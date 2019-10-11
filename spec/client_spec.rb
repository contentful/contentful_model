require 'spec_helper'

describe ContentfulModel::Client do
  subject do
    described_class.new({
      space: 'cfexampleapi',
      access_token: 'b4c0n73n7fu1',
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
    })
  end

  it 'is a Contentful::Client' do
    vcr('client') {
      expect(subject).to be_a(Contentful::Client)
    }
  end

  it 'gets initialized with the configured delivery specific timeout_connect' do
    vcr('client') {
      expect(subject.configuration[:timeout_connect]).to eq(4)
    }
  end
end
