require 'spec_helper'

class InvalidSaveCat < ContentfulModel::Base
  self.content_type_id = 'cat'

  validate :always_fail, -> (e) { false }
end

describe ContentfulModel::Manageable do
  before :each do
    ContentfulModel.configure do |c|
      c.default_locale = 'en-US'
      c.management_token = '<ACCESS_TOKEN>'
      c.access_token = '4d0f55d940975f78139daae5d965b463c0816e88ad16062d2c1ee3d6cb930521'
      c.space = 'facgnwwgj5fe'
      c.entry_mapping = {}
    end

    InvalidSaveCat.client = nil
    Cat.client = nil
  end

  let(:space_id) { 'facgnwwgj5fe' }
  let(:entry_id) { 'IJLRrADsqq2AmwcugoYeK' }
  subject { vcr('playground/nyancat') { Cat.find(entry_id) } }

  describe 'class methods' do
    it '::management' do
      expect(Cat.management).to be_a(ContentfulModel::Management)
    end

    describe '::create' do
      before do
        @mock_client = Object.new
        @mock_ct = Object.new
        @mock_entry = Object.new
        allow(Cat).to receive(:management) { @mock_client }
        allow(@mock_client).to receive(:entries) { @mock_client }
        allow(@mock_client).to receive(:content_types) { @mock_client }
        allow(@mock_client).to receive(:find).with('cat') { @mock_ct }
        @values = {'name' => 'Nyan Cat'}
      end

      it 'creates an entry' do
        expect(@mock_client).to receive(:create).with(@mock_ct, @values) { @mock_entry }

        Cat.create(@values)
      end

      it 'publishes after creation' do
        allow(@mock_client).to receive(:create).with(@mock_ct, @values) { @mock_entry }
        allow(@mock_entry).to receive(:id) { entry_id }
        allow(Cat).to receive(:find).with(entry_id) { @mock_entry }
        expect(@mock_entry).to receive(:publish)

        Cat.create(@values, true)
      end
    end
  end

  describe 'instance methods' do
    it '#to_management' do
      vcr('management/client') {
        expect(subject.to_management).to be_a(Contentful::Management::Entry)
        expect(subject.to_management.id).to eq(entry_id)
      }
    end

    it 'creates setters for fields' do
      expect(subject.respond_to?(:name=)).to be_truthy
    end

    it 'allows to override values' do
      expect(subject.name).to eq('Nyan Cat')
      subject.name = 'Fat Cat'
      expect(subject.name).to eq('Fat Cat')
    end

    context 'modifying the space' do
      describe '#save' do
        it 'fails on invalid instance' do
          vcr('management/nyancat') {
            subject = InvalidSaveCat.find(entry_id)

            expect(subject).not_to receive(:to_management)

            expect(subject.save).to be_falsey

            expect(subject.errors).to match_array [
              'always_fail: validation not met'
            ]
          }
        end

        it 'calls #save on management object' do
          vcr('management/nyancat') {
            subject = Cat.find(entry_id)

            version = subject.to_management.sys[:version]

            expect(subject.name).to eq 'Nyan Cat'

            subject.name = 'Fat Cat'
            vcr('management/nyancat_save') {
              subject.save

              expect(subject.to_management.sys[:version]).to eq(version + 1)
            }
          }
        end

        it 'sets dirty to false' do
          vcr('management/nyancat') {
            subject = Cat.find(entry_id)

            expect(subject.dirty).to be_falsey

            subject.name = 'Fat Cat'

            expect(subject.dirty).to be_truthy
            vcr('management/nyancat_save') {
              subject.save

              expect(subject.dirty).to be_falsey
            }
          }
        end

        it 'refetches management entry if conflict occurs' do
          vcr('management/nyancat') {
            subject = Cat.find(entry_id)

            vcr('management/nyancat_refetch_and_save') {
              expect(subject).to receive(:refetch_management_entry).and_call_original

              subject.name = 'Foo Cat'
              subject.save
            }
          }
        end

        it 'raises error if conflict happens after refetch' do
          vcr('management/nyancat') {
            subject = Cat.find(entry_id)

            vcr('management/nyancat_refetch_and_fail') {
              expect(subject).to receive(:refetch_management_entry).and_call_original

              subject.name = 'Foo Cat'

              expect { subject.save }.to raise_error ContentfulModel::VersionMismatchError
            }
          }
        end
      end

      describe '#publish' do
        it 'calls #publish on management object' do
          vcr('management/nyancat_2') {
            subject = Cat.find(entry_id)

            version = subject.to_management.sys[:version]

            expect(subject.name).to eq 'Nyan Cat'

            subject.name = 'Fat Cat'
            vcr('management/nyancat_save_2') {
              subject.save

              management_subject = subject.to_management
              published_at = management_subject.sys[:publishedAt]
              expect(management_subject.sys[:version]).to eq(version + 1)
              vcr('management/nyancat_publish') {
                subject.publish

                management_subject = subject.to_management
                expect(management_subject.sys[:version]).to eq(version + 2)
                expect(management_subject.sys[:publishedAt]).not_to eq(published_at)
              }
            }
          }
        end
      end
    end
  end
end
