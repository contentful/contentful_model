require 'spec_helper'

class MockSpace
  attr_reader :id

  def initialize(id)
    @id = id
  end
end

class MockManageable < ContentfulModel::Base
  self.content_type_id = 'ct_id'

  attr_reader :id, :fields, :space, :locale

  def initialize(id, space, fields = {})
    @id = id
    @fields = fields
    @space = space
    @locale = 'en-US'
    super([])
  end
end

describe ContentfulModel::Manageable do
  before do
    ContentfulModel.configure do |c|
      c.default_locale = 'en-US'
      c.management_token = 'foo'
      c.space = 'bar'
    end
  end

  let(:space) { MockSpace.new('space_id') }
  subject { MockManageable.new('entry_id', space) }

  describe 'class methods' do
    it '::management' do
      expect(MockManageable.management).to be_a(ContentfulModel::Management)
    end

    describe '::create' do
      before do
        @mock_client = Object.new
        @mock_ct = Object.new
        @mock_entry = Object.new
        allow(MockManageable).to receive(:management) { @mock_client }
        allow(@mock_client).to receive(:entries) { @mock_client }
        allow(@mock_client).to receive(:content_types) { @mock_client }
        allow(@mock_client).to receive(:find).with('bar', 'ct_id') { @mock_ct }
        @values = {foo: 'bar'}
      end

      it 'creates an entry' do
        expect(@mock_client).to receive(:create).with(@mock_ct, @values) { @mock_entry }

        MockManageable.create(@values)
      end

      it 'publishes after creation' do
        allow(@mock_client).to receive(:create).with(@mock_ct, @values) { @mock_entry }
        allow(@mock_entry).to receive(:id) { 'entry_id' }
        allow(MockManageable).to receive(:find).with('entry_id') { @mock_entry }
        expect(@mock_entry).to receive(:publish)

        MockManageable.create(@values, true)
      end
    end
  end

  describe 'instance methods' do
    it '#to_management' do
      mock_client = Object.new
      allow(MockManageable).to receive(:management) { mock_client }
      allow(mock_client).to receive(:spaces) { mock_client }
      allow(mock_client).to receive(:find) { space }
      allow(space).to receive(:entries) { space }
      allow(space).to receive(:find).with('entry_id') { Contentful::Management::Entry.new({'sys' => {'id' => 'entry_id'}}) }

      expect(subject.to_management).to be_a(Contentful::Management::Entry)
      expect(subject.to_management.id).to eq('entry_id')
    end

    it 'creates setters for fields' do
      subject = MockManageable.new('entry_id', space, {foo: 1})

      expect(subject.respond_to?(:foo=)).to be_truthy
    end

    it 'allows to override values' do
      subject = MockManageable.new('entry_id', space, {foo: 1})

      expect(subject.foo).to eq(1)

      subject.foo = 2

      expect(subject.foo).to eq(2)
    end

    describe '#save' do
      it 'calls #save on management object' do
        mock_management = Object.new
        expect(subject).to receive(:to_management) { mock_management }
        expect(mock_management).to receive(:save)

        subject.save
      end

      it 'sets dirty to false' do
        subject = MockManageable.new('entry_id', space, {foo: 1})
        mock_management = Object.new
        allow(subject).to receive(:to_management) { mock_management }
        allow(mock_management).to receive(:save)

        expect(subject.dirty).to be_falsey

        subject.foo = 2

        expect(subject.dirty).to be_truthy

        subject.save

        expect(subject.dirty).to be_falsey
      end
    end

    describe '#publish' do
      it 'calls #publish on management object' do
        mock_management = Object.new
        expect(subject).to receive(:to_management) { mock_management }
        expect(mock_management).to receive(:publish)

        subject.publish
      end
    end
  end
end
