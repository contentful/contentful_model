require 'spec_helper'

class HumanWithMethods < ContentfulModel::Base
  self.content_type_id = 'human'

  def foo
    'bar'
  end

  def profile
    [
      "Name: #{name}",
      "Description: #{description}",
      "Likes: #{likes.join(', ')}"
    ].join("\n")
  end
end

module Models
  class NestedDog < ContentfulModel::Base
    self.content_type_id = 'dog'
  end
end

describe ContentfulModel::Base do
  subject { vcr('nyancat') { Cat.find('nyancat') } }

  before :each do
    ContentfulModel.configure do |config|
      config.space = 'cfexampleapi'
      config.access_token = 'b4c0n73n7fu1'
      config.entry_mapping = {}
    end
  end

  describe 'class methods' do
    it '::client' do
      vcr('client') {
        expect(Cat.client).to be_a ContentfulModel::Client
      }
    end

    it '::content_type' do
      vcr('base/content_type') {
        content_type = Cat.content_type
        expect(content_type.id).to eq 'cat'
        expect(content_type).to be_a Contentful::ContentType
      }
    end
  end

  describe 'initialization' do
    it 'creates getters on initialize for each field' do
      expect(subject.respond_to?(:foobar)).to be_falsey
      expect(subject.respond_to?(:name)).to be_truthy
      expect(subject.respond_to?(:lives)).to be_truthy
    end
  end

  describe "coercion" do
    it "applies to the getters created for each field" do
      vcr('nyancat') {
        nyancat = CoercedCat.find('nyancat')
        expect(nyancat.name).to eq 'Fat Cat'
        expect(nyancat.created_at).to eq '2013-06-27T22:46:19+00:00'
      }
    end
  end

  describe "#coerce_field" do
    it "returns the value for fields that have no coercion" do
      title = 'CMS of the future'
      expect(CoercedCat.coerce_value(:title, title)).to eq title
    end

    context "the fields coercion is a Proc" do
      it "call the proc with the value and returns the result" do
        expect(CoercedCat.coerce_value(:name, 'Nyan man')).to eq 'Fat man'
      end
    end

    context "the fields coercion is a Symbol" do
      it "calls the builtin coercion with the value and returns the result" do
        date = '2016-12-06T11:00+00:00'
        expect(CoercedCat.coerce_value(:updated_at, date))
          .to be_instance_of(DateTime)
      end
    end
  end

  describe "#cache_key" do
    subject(:contentful_object) { vcr('nyancat') { Cat.find('nyancat') } }

    it "can be found by #responds_to?" do
      expect(contentful_object).to respond_to(:cache_key)
    end

    it "starts with the objects model name"do
      expect(contentful_object.cache_key).to start_with("cat/")
    end

    it "contains the objects id" do
      expect(contentful_object.cache_key).to include(contentful_object.id.to_s)
    end

    it "contains the objects updated timestamp" do
      expect(contentful_object.cache_key)
        .to include(contentful_object.updated_at.utc.to_s(:usec))
    end
  end

  it '#hash' do
    vcr('nyancat') {
      nyancat = Cat.find('nyancat')
      expect(nyancat.hash).to eq 'cat-nyancat'.hash
    }
  end

  it '#eql?' do
    nyancat = nil
    other_nyan = nil

    vcr('nyancat') { nyancat = Cat.find('nyancat') }
    vcr('nyancat') { other_nyan = Cat.find('nyancat') }

    expect(nyancat == other_nyan).to be_truthy
  end

  describe 'base children should be able to have user defined methods' do
    it 'has a user defined method' do
      vcr('human') {
        human = HumanWithMethods.first
        expect(human.foo).to eq 'bar'
      }
    end

    it 'has a user defined method that uses some entry field' do
      vcr('human') {
        human = HumanWithMethods.first
        profile = human.profile

        expect(profile).to include("Name: Finn")
        expect(profile).to include("Description: Fearless adventurer! Defender of pancakes.")
        expect(profile).to include("Likes: adventure")
      }
    end
  end

  describe 'base children can be defined in nested modules' do
    it 'does not fail to fetch entries' do
      dog = nil
      vcr('dog') {
        expect {
          dog = Models::NestedDog.first
        }.not_to raise_error

        expect(dog.name).to eq 'Jake'
      }
    end
  end
end

