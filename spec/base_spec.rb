require 'spec_helper'

describe ContentfulModel::Base do
  let(:space) { MockSpace.new('foo_space') }

  before do
    ContentfulModel.configure do |config|
      config.space = 'cfexampleapi'
      config.access_token = 'b4c0n73n7fu1'
      config.entry_mapping = {}
    end
  end

  describe 'class methods' do
    it '::client' do
      vcr('client') {
        expect(MockBase.client).to be_a ContentfulModel::Client
      }
    end

    it '::content_type' do
      vcr('client') {
        expect(MockBase.client).to receive(:content_type).with('ct_id') { 'ct_id' }
        expect(MockBase.content_type).to eq 'ct_id'
      }
    end
  end

  describe 'initialization' do
    it 'creates getters on initialize for each field' do
      vcr('client') {
        expect(MockBase.new('entry_id', space).respond_to?(:foo)).to be_falsey

        expect(MockBase.new('entry_id', space, {'foo' => {'en-US' => 'bar'}}).respond_to?(:foo)).to be_truthy
        expect(MockBase.new('entry_id', space, {'foo' => {'en-US' => 'bar'}}).foo).to eq 'bar'
      }
    end
  end

  describe "#cache_key" do
    subject(:contentful_object) { MockBase.new('entry_id', space, {'updated_at' => {'en-US' => Time.now}}) }

    it "can be found by #responds_to?" do
      expect(contentful_object).to respond_to(:cache_key)
    end

    it "starts with the objects model name" do
      expect(contentful_object.cache_key).to start_with("mock_base/")
    end

    it "contains the objects id" do
      expect(contentful_object.cache_key).to include(contentful_object.id.to_s)
    end

    it "contains the objects updated timestamp" do
      expect(contentful_object.cache_key)
        .to include(contentful_object.updated_at.utc.to_s(:usec))
    end
  end
end

