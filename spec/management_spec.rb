require 'spec_helper'

describe ContentfulModel::Management do
  before do
    ContentfulModel.configure do |c|
      c.management_token = 'foobar'
    end
  end

  it 'is a Contentful::Management::Client' do
    expect(subject).to be_a(Contentful::Management::Client)
  end

  it 'gets initialized with the configured management token' do
    expect(subject.access_token).to eq('foobar')
  end
end
