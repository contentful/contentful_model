require 'spec_helper'

class MockChainQueriable
  include ContentfulModel::Queries

  class << self
    attr_accessor :content_type_id
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

describe ContentfulModel::Base do
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

      it 'returns a query object' do
        expect(subject.all).to be_a ContentfulModel::Query
      end
    end

    it '::params' do
      query = subject.params({'include' => 1})
      expect(query.parameters).to include('include' => 1)
    end

    it '::first' do
      expect_any_instance_of(ContentfulModel::Query).to receive(:load) { ['first'] }
      expect(subject.first).to eq 'first'
    end

    it '::skip' do
      query = subject.skip(2)
      expect(query.parameters).to include('skip' => 2)
    end

    it '::offset' do
      query = subject.offset(3)
      expect(query.parameters).to include('skip' => 3)
    end

    it '::limit' do
      query = subject.limit(4)
      expect(query.parameters).to include('limit' => 4)
    end

    it '::locale' do
      query = subject.locale('en-US')
      expect(query.parameters).to include('locale' => 'en-US')
    end

    it '::load_children' do
      query = subject.load_children(4)
      expect(query.parameters).to include('include' => 4)
    end

    describe '::order' do
      describe 'when parameter is a hash' do
        it 'ascending' do
          query = subject.order(foo: :asc)
          expect(query.parameters).to include('order' => 'fields.foo')
        end

        it 'descending' do
          query = subject.order(foo: :desc)
          expect(query.parameters).to include('order' => '-fields.foo')
        end
      end

      it 'when param is a symbol' do
        query = subject.order(:foo)
        expect(query.parameters).to include('order' => 'fields.foo')
      end

      it 'when param is a string' do
        query = subject.order('foo')
        expect(query.parameters).to include('order' => 'fields.foo')
      end

      it 'when param is a sys property' do
        query = subject.order(:created_at)
        expect(query.parameters).to include('order' => 'sys.createdAt')
      end
    end

    describe '::find_by' do
      it 'when value is an array' do
        query = subject.find_by(foo: [1, 2, 3])
        expect(query.parameters).to include('fields.foo[in]' => '1,2,3')
      end

      it 'when value is a string' do
        query = subject.find_by(foo: 'bar')
        expect(query.parameters).to include('fields.foo' => 'bar')
      end

      it 'when value is a number' do
        query = subject.find_by(foo: 1)
        expect(query.parameters).to include('fields.foo' => 1)
      end

      it 'when value is a boolean' do
        query = subject.find_by(foo: true)
        expect(query.parameters).to include('fields.foo' => true)
      end

      it 'when value is a hash' do
        query = subject.find_by(foo: {gte: 123})
        expect(query.parameters).to include('fields.foo[gte]' => 123)
      end

      it 'when multiple fields' do
        query = subject.find_by(foo: true, bar: 123)
        expect(query.parameters).to include('fields.foo' => true , 'fields.bar' => 123)
      end

      it 'supports sys fields' do
        query = subject.find_by('sys.id': 'foo')
        expect(query.parameters).to include('sys.id' => 'foo')
      end

      it 'support sys properties without prefix' do
        query = subject.find_by('updatedAt' => 'foo')
        expect(query.parameters).to include('sys.updatedAt' => 'foo')
      end
    end

    describe '::paginate' do
      it 'defaults to first page and 100 items and sort by updatedAt' do
        query = subject.paginate
        expect(query.parameters).to include('limit' => 100, 'skip' => 0, 'order' => 'sys.updatedAt')
      end

      it 'requesting second page will add page_size to skip' do
        query = subject.paginate(2)
        expect(query.parameters).to include('limit' => 100, 'skip' => 100)
      end

      it 'can change page_size' do
        query = subject.paginate(1, 20)
        expect(query.parameters).to include('limit' => 20, 'skip' => 0)
      end

      it 'can change page_size and select a different page' do
        query = subject.paginate(3, 20)
        expect(query.parameters).to include('limit' => 20, 'skip' => 40)
      end

      it 'outliers are changed to default values' do
        query = subject.paginate(-1, 'foo')
        expect(query.parameters).to include('limit' => 100, 'skip' => 0)
      end

      it 'can sort by a different field' do
        query = subject.paginate(1, 100, 'sys.createdAt')
        expect(query.parameters).to include('limit' => 100, 'skip' => 0, 'order' => 'sys.createdAt')
      end
    end

    describe '::search' do
      describe 'when parameter is a hash' do
        it 'when value is a string performs "match"' do
          query = subject.search(foo: 'bar')
          expect(query.parameters).to include('fields.foo[match]' => 'bar')
        end

        it 'when value is a hash performs query based on hash key' do
          query = subject.search(foo: {gte: 123})
          expect(query.parameters).to include('fields.foo[gte]' => 123)
        end
      end

      it 'when parameter is a string, performs full text search using "query"' do
        query = subject.search('foobar')
        expect(query.parameters).to include('query' => 'foobar')
      end
    end
  end
end
