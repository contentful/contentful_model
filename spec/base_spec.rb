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

        expect(MockBase.new('entry_id', space, {'fields' => {'foo' => {'en-US' => 'bar'}}}).respond_to?(:foo)).to be_truthy
        expect(MockBase.new('entry_id', space, {'fields' => {'foo' => {'en-US' => 'bar'}}}).foo).to eq 'bar'
      }
    end
  end

  describe "coercion" do
    it "applies to the getters created for each field" do
      klass = new_contentful_model{ coerce_field published_at: :date }
      entry = klass.new('entry_id', space, {
        'fields' => { 'publishedAt' => {'en-US' => '2016-12-06T11:00+00:00'} }
      })

      vcr('client') {
        expect(entry.published_at).to be_instance_of(DateTime)
      }
    end
  end

  describe "#coerce_field" do
    let(:klass) {
      new_contentful_model do
        coerce_field view_count: ->(original) { original.to_i * 100 }
        coerce_field published_at: :date
      end
    }

    it "returns the value for fields that have no coercion" do
      title = 'CMS of the future'
      expect(klass.coerce_value(:title, title)).to eq(title)
    end

    context "the fields coercion is a Proc" do
      it "call the proc with the value and returns the result" do
        count = '2'
        expect(klass.coerce_value(:view_count, count)).to eq(200)
      end
    end

    context "the fields coercion is a Symbol" do
      it "calls the builtin coercion with the value and returns the result" do
        date = '2016-12-06T11:00+00:00'
        expect(klass.coerce_value(:published_at, date))
          .to be_instance_of(DateTime)
      end
    end
  end

  describe "#cache_key" do
    subject(:contentful_object) { MockBase.new('entry_id', space, {'sys' => {'updatedAt' => Time.now.to_s}, 'fields' => []}) }

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

