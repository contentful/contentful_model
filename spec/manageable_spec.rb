require 'spec_helper'

describe ContentfulModel::Manageable do
  before do
    ContentfulModel.configure do |c|
      c.default_locale = 'en-US'
      c.management_token = 'foo'
      c.access_token = 'foobar'
      c.space = 'cfexampleapi'
    end
  end

  let(:space) { MockSpace.new('space_id') }
  subject { MockBase.new('entry_id', space) }

  describe 'class methods' do
    it '::management' do
      expect(MockBase.management).to be_a(ContentfulModel::Management)
    end

    describe '::create' do
      before do
        @mock_client = Object.new
        @mock_ct = Object.new
        @mock_entry = Object.new
        allow(MockBase).to receive(:management) { @mock_client }
        allow(@mock_client).to receive(:entries) { @mock_client }
        allow(@mock_client).to receive(:content_types) { @mock_client }
        allow(@mock_client).to receive(:find).with('cfexampleapi', 'ct_id') { @mock_ct }
        @values = {'foo' => 'bar'}
      end

      it 'creates an entry' do
        expect(@mock_client).to receive(:create).with(@mock_ct, @values) { @mock_entry }

        MockBase.create(@values)
      end

      it 'publishes after creation' do
        allow(@mock_client).to receive(:create).with(@mock_ct, @values) { @mock_entry }
        allow(@mock_entry).to receive(:id) { 'entry_id' }
        allow(MockBase).to receive(:find).with('entry_id') { @mock_entry }
        expect(@mock_entry).to receive(:publish)

        MockBase.create(@values, true)
      end
    end
  end

  describe 'instance methods' do
    it '#to_management' do
      vcr('client') {
        mock_management_client = Object.new
        mock_entry = Object.new
        allow_any_instance_of(ContentfulModel::Client).to receive(:space)
        allow_any_instance_of(ContentfulModel::Client).to receive(:entry) { mock_entry }
        allow(MockBase).to receive(:management) { mock_management_client }
        allow(mock_management_client).to receive(:spaces) { mock_management_client }
        allow(mock_management_client).to receive(:find) { space }
        allow(space).to receive(:entries) { space }
        allow(space).to receive(:find).with('entry_id') { Contentful::Management::Entry.new({'sys' => {'id' => 'entry_id'}}) }

        expect(subject.to_management).to be_a(Contentful::Management::Entry)
        expect(subject.to_management.id).to eq('entry_id')
      }
    end

    it 'creates setters for fields' do
      subject = MockBase.new('entry_id', space, {'foo' => {'en-US' => 1 }})

      expect(subject.respond_to?(:foo=)).to be_truthy
    end

    it 'allows to override values' do
      subject = MockBase.new('entry_id', space, {'foo' =>  {'en-US' => 1 }})

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
        subject = MockBase.new('entry_id', space, {'foo' =>  {'en-US' => 1 }})
        mock_management = Object.new
        allow(subject).to receive(:to_management) { mock_management }
        allow(mock_management).to receive(:save)

        expect(subject.dirty).to be_falsey

        subject.foo = 2

        expect(subject.dirty).to be_truthy

        subject.save

        expect(subject.dirty).to be_falsey
      end

      it 'refetches management entry if conflict occurs' do
        subject = MockBase.new('entry_id', space, {'foo' =>  {'en-US' => 1 }})
        mock_management = Object.new
        new_management_entry = Object.new
        allow(subject).to receive(:to_management) { mock_management }

        dummy_http = Object.new
        allow(dummy_http).to receive(:request) { dummy_http }
        allow(dummy_http).to receive(:endpoint) { dummy_http }
        allow(dummy_http).to receive(:error_message)
        allow(dummy_http).to receive(:raw) { dummy_http }
        allow(dummy_http).to receive(:body)

        expect(mock_management).to receive(:save).and_raise(Contentful::Management::Conflict.new(dummy_http))
        expect(subject).to receive(:refetch_management_entry) { new_management_entry }

        expect(subject).to receive(:to_management) { mock_management }
        expect(subject).to receive(:to_management).with(new_management_entry) { new_management_entry }

        expect(new_management_entry).to receive(:save)

        subject.save
      end

      it 'raises error if conflict happens after refetch' do
        subject = MockBase.new('entry_id', space, {'foo' =>  {'en-US' => 1 }})
        mock_management = Object.new
        new_management_entry = Object.new
        allow(subject).to receive(:to_management) { mock_management }

        dummy_http = Object.new
        allow(dummy_http).to receive(:request) { dummy_http }
        allow(dummy_http).to receive(:endpoint) { dummy_http }
        allow(dummy_http).to receive(:error_message)
        allow(dummy_http).to receive(:raw) { dummy_http }
        allow(dummy_http).to receive(:body)

        expect(mock_management).to receive(:save).and_raise(Contentful::Management::Conflict.new(dummy_http))
        expect(subject).to receive(:refetch_management_entry) { new_management_entry }

        expect(subject).to receive(:to_management) { mock_management }
        expect(subject).to receive(:to_management).with(new_management_entry) { new_management_entry }

        expect(new_management_entry).to receive(:save).and_raise(Contentful::Management::Conflict.new(dummy_http))

        expect { subject.save }.to raise_error ContentfulModel::VersionMismatchError
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
