require 'spec_helper'

class NameValidation
  def validate(entry)
    return [] if entry.name == 'Nyan Cat'
    ['Invalid Entry']
  end
end

class InvalidatedCat < ContentfulModel::Base
  self.content_type_id = 'cat'

  validate_with NameValidation.new, on_load: true
end

describe ContentfulModel::Queries do
  before :each do
    ContentfulModel.configure do |config|
      config.space = 'cfexampleapi'
      config.access_token = 'b4c0n73n7fu1'
      config.entry_mapping = {}
    end

    Cat.client = nil
    Cat.instance_variable_set(:@query, ContentfulModel::Query.new(Cat))

    InvalidatedCat.client = nil
    InvalidatedCat.instance_variable_set(:@query, ContentfulModel::Query.new(InvalidatedCat))
  end

  describe 'class methods' do
    describe '::load' do
      it 'returns the base query "/entries"' do
        vcr('query/load') {
          response = Cat.load
          expect(response).to be_a ::Contentful::Array
          expect(response.items.size).to eq 3
          expect(response.total).to eq 3
        }
      end

      it 'filters out invalid elements' do
        vcr('query/load') {
          response = InvalidatedCat.load
          expect(response).to be_a ::Contentful::Array
          expect(response.items.size).to eq 1
          expect(response.total).to eq 3
        }
      end
    end

    it '::find' do
      vcr('nyancat') {
        nyancat = Cat.find('nyancat')
        expect(nyancat).to be_a Cat
        expect(nyancat.name).to eq 'Nyan Cat'
        expect(nyancat.id).to eq 'nyancat'
      }
    end

    it '::paginate' do
      vcr('query/manual_pagination') {
        happy_cat = Cat.paginate(2, 2).load.first
        expect(happy_cat.name).to eq 'Happy Cat'
      }
    end

    it '::each_page' do
      vcr('query/each_page') {
        Cat.each_page(2) do |page|
          expect(page).to be_a ::Contentful::Array
          expect(page.first).to be_a Cat
        end
      }
    end

    it '::each_entry' do
      vcr('query/each_entry') {
        Cat.each_entry(2) do |cat|
          expect(cat).to be_a Cat
        end
      }
    end
  end
end
