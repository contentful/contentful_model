require 'spec_helper'

class MockChainQueriable
  include ContentfulModel::ChainableQueries

  class << self
    attr_accessor :content_type_id, :query
  end
end

class MockChainQueriableEntry < MockChainQueriable
  self.content_type_id = 'foo'

  def self.client
    @@client ||= MockClient.new
  end

  def invalid?
    false
  end
end

describe ContentfulModel::ChainableQueries do
  subject { MockChainQueriableEntry }

  before do
    subject.content_type_id = 'foo'
  end

  describe 'class methods' do
    describe '::all' do
      it 'fails if no content type is set' do
        subject.content_type_id = nil
        expect { subject.all }.to raise_error 'You need to set self.content_type in your model class'
      end

      it 'returns itself' do
        expect(subject.all).to eq subject
      end
    end

    it '::params' do
      expect(subject.params({'include' => 1})).to eq subject
      expect(subject.query.parameters).to include('include' => 1)
    end

    it '::first' do
      allow(subject).to receive(:load) { ['first'] }
      expect(subject.first).to eq 'first'
      expect(subject.query.parameters).to include('limit' => 1)
    end

    it '::skip' do
      expect(subject.skip(2)).to eq subject
      expect(subject.query.parameters).to include('skip' => 2)
    end

    it '::offset' do
      expect(subject.offset(3)).to eq subject
      expect(subject.query.parameters).to include('skip' => 3)
    end

    it '::limit' do
      expect(subject.limit(4)).to eq subject
      expect(subject.query.parameters).to include('limit' => 4)
    end

    it '::locale' do
      expect(subject.locale('en-US')).to eq subject
      expect(subject.query.parameters).to include('locale' => 'en-US')
    end

    it '::load_children' do
      expect(subject.load_children(4)).to eq subject
      expect(subject.query.parameters).to include('include' => 4)
    end

    describe '::order' do
      describe 'when parameter is a hash' do
        it 'ascending' do
          expect(subject.order(foo: :asc)).to eq subject
          expect(subject.query.parameters).to include('order' => 'fields.foo')
        end

        it 'descending' do
          expect(subject.order(foo: :desc)).to eq subject
          expect(subject.query.parameters).to include('order' => '-fields.foo')
        end
      end

      it 'when param is a symbol' do
        expect(subject.order(:foo)).to eq subject
        expect(subject.query.parameters).to include('order' => 'fields.foo')
      end

      it 'when param is a string' do
        expect(subject.order('foo')).to eq subject
        expect(subject.query.parameters).to include('order' => 'fields.foo')
      end

      it 'when param is a sys property' do
        expect(subject.order(:created_at)).to eq subject
        expect(subject.query.parameters).to include('order' => 'sys.createdAt')
      end
    end

    describe '::find_by' do
      it 'when value is an array' do
        expect(subject.find_by(foo: [1, 2, 3])).to eq subject
        expect(subject.query.parameters).to include('fields.foo[in]' => '1,2,3')
      end

      it 'when value is a string' do
        expect(subject.find_by(foo: 'bar')).to eq subject
        expect(subject.query.parameters).to include('fields.foo' => 'bar')
      end

      it 'when value is a number' do
        expect(subject.find_by(foo: 1)).to eq subject
        expect(subject.query.parameters).to include('fields.foo' => 1)
      end

      it 'when value is a boolean' do
        expect(subject.find_by(foo: true)).to eq subject
        expect(subject.query.parameters).to include('fields.foo' => true)
      end

      it 'when value is a hash' do
        expect(subject.find_by(foo: {gte: 123})).to eq subject
        expect(subject.query.parameters).to include('fields.foo[gte]' => 123)
      end

      it 'when multiple fields' do
        expect(subject.find_by(foo: true, bar: 123)).to eq subject
        expect(subject.query.parameters).to include('fields.foo' => true , 'fields.bar' => 123)
      end

      it 'supports sys fields' do
        expect(subject.find_by('sys.id': 'foo')).to eq subject
        expect(subject.query.parameters).to include('sys.id' => 'foo')
      end
    end

    describe '::paginate' do
      it 'defaults to first page and 100 items and sort by updatedAt' do
        expect(subject.paginate).to eq subject
        expect(subject.query.parameters).to include('limit' => 100, 'skip' => 0, 'order' => 'sys.updatedAt')
      end

      it 'requesting second page will add page_size to skip' do
        expect(subject.paginate(2)).to eq subject
        expect(subject.query.parameters).to include('limit' => 100, 'skip' => 100)
      end

      it 'can change page_size' do
        expect(subject.paginate(1, 20)).to eq subject
        expect(subject.query.parameters).to include('limit' => 20, 'skip' => 0)
      end

      it 'can change page_size and select a different page' do
        expect(subject.paginate(3, 20)).to eq subject
        expect(subject.query.parameters).to include('limit' => 20, 'skip' => 40)
      end

      it 'outliers are changed to default values' do
        expect(subject.paginate(-1, 'foo')).to eq subject
        expect(subject.query.parameters).to include('limit' => 100, 'skip' => 0)
      end

      it 'can sort by a different field' do
        expect(subject.paginate(1, 100, 'sys.createdAt')).to eq subject
        expect(subject.query.parameters).to include('limit' => 100, 'skip' => 0, 'order' => 'sys.createdAt')
      end
    end

    describe '::search' do
      describe 'when parameter is a hash' do
        it 'when value is a string performs "match"' do
          expect(subject.search(foo: 'bar')).to eq subject
          expect(subject.query.parameters).to include('fields.foo[match]' => 'bar')
        end

        it 'when value is a hash performs query based on hash key' do
          expect(subject.search(foo: {gte: 123})).to eq subject
          expect(subject.query.parameters).to include('fields.foo[gte]' => 123)
        end
      end

      it 'when parameter is a string, performs full text search using "query"' do
        expect(subject.search('foobar')).to eq subject
        expect(subject.query.parameters).to include('query' => 'foobar')
      end
    end
  end
end
