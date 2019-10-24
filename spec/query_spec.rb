require 'spec_helper'

class Foo < ContentfulModel::Base
end

class OneInclude < ContentfulModel::Base
  has_one :foo
end

class MultiInclude < ContentfulModel::Base
  has_one :one_include
end

class CircularInclude < ContentfulModel::Base
  has_many :to_circulars
end

class ToCircular < ContentfulModel::Base
  has_one :circular_include
end

class Bar < ContentfulModel::Base
end

class MultiIncludeWithVaryingReferenceDepth < ContentfulModel::Base
  has_one :one_include
  has_one :bar
end

describe ContentfulModel::Query do
  let(:parameters) { { 'sys.id' => 'foo' } }
  let(:entry) { vcr('nyancat') { Cat.find('nyancat') } }
  subject { described_class.new(Cat, parameters) }

  before :each do
    ContentfulModel.configure do |config|
      config.space = 'cfexampleapi'
      config.access_token = 'b4c0n73n7fu1'
      config.entry_mapping = {}
    end
  end

  describe 'attributes' do
    it ':parameters' do
      expect(subject.parameters).to eq parameters
    end
  end

  describe 'instance_methods' do
    before :each do
      Cat.client = nil
    end

    it '#<< updates parameters' do
      expect(subject.parameters).to eq parameters

      subject << {foo: 'bar'}

      expect(subject.parameters).to eq parameters.merge(foo: 'bar')
    end

    it '#default_parameters' do
      expect(subject.default_parameters).to eq('content_type' => 'cat')
    end

    it '#client' do
      vcr('client') {
        expect(subject.client).to eq Cat.client
      }
    end

    it '#reset' do
      subject << {'foo' => 'bar'}

      subject.reset

      expect(subject.parameters).to eq subject.default_parameters
    end

    describe '#execute' do
      it 'when response is empty' do
        vcr('query/empty') {
          expect(subject.execute.items).to eq []
        }
      end

      it 'when response contains items' do
        query = described_class.new(Cat, 'sys.id' => 'nyancat')
        vcr('nyancat') {
          entries = query.execute
          expect(entries.first.id).to eq 'nyancat'
        }
      end
    end

    describe '#load!' do
      it 'raises an error when response is empty' do
        vcr('query/empty') {
          expect { subject.load! }.to raise_error ContentfulModel::NotFoundError
        }
      end

      it 'returns items when response is not empty' do
        query = described_class.new(Cat, 'sys.id' => 'nyancat')
        vcr('nyancat') {
          entries = query.load!
          expect(entries.first.id).to eq 'nyancat'
        }
      end
    end

    describe '#discover_includes' do
      it 'defaults to 1 for a class without associations' do
        query = described_class.new(Cat)
        expect(query.discover_includes).to eq 1
      end

      it 'adds an include level if it finds another nested item' do
        query = described_class.new(OneInclude)
        expect(query.discover_includes).to eq 2
      end

      it 'follows the include chain' do
        query = described_class.new(MultiInclude)
        expect(query.discover_includes).to eq 3
      end

      it 'can support circular references' do
        query = described_class.new(CircularInclude)
        expect(query.discover_includes).to eq 2

        query = described_class.new(ToCircular)
        expect(query.discover_includes).to eq 2
      end

      it 'when having multiple reference chains, include is set to the maximum chain legth' do
        query = described_class.new(MultiIncludeWithVaryingReferenceDepth)
        expect(query.discover_includes).to eq 3
      end
    end
  end
end
