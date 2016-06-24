require 'spec_helper'

describe ContentfulModel::Client do
  subject { described_class.new({space: 'cfexampleapi', access_token: 'b4c0n73n7fu1'}) }

  it 'is a Contentful::Client' do
    expect(subject).to be_a(Contentful::Client)
  end
end
