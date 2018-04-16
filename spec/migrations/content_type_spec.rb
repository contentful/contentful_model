require 'spec_helper'

describe ContentfulModel::Migrations::ContentType do
  describe 'instance methods' do
    describe '#new?' do
      it 'newly created returns true' do
        expect(described_class.new.new?).to be_truthy
      end

      it 'returns true if management content type present but no id' do
        mock_ct = Object.new
        allow(mock_ct).to receive(:id) { nil }

        expect(described_class.new(nil, mock_ct).new?).to be_truthy
      end

      it 'returns false if management content type present with id' do
        mock_ct = Object.new
        allow(mock_ct).to receive(:id) { 'foo' }

        expect(described_class.new(nil, mock_ct).new?).to be_falsey
      end
    end

    describe '#save' do
      before do
        ContentfulModel.configure do |c|
          c.space = 'space_id'
          c.management_token = 'token'
        end
      end

      it 'creates a new content type on contentful' do
        mock_client = Object.new
        expect(mock_client).to receive(:create).with(id: 'foo', name: 'foo', fields: [])
        allow_any_instance_of(ContentfulModel::Management).to receive(:content_types) { mock_client }

        described_class.new('foo').save
      end

      it 'updates an existing content type' do
        mock_ct = Object.new
        allow(mock_ct).to receive(:id) { 'foo' }

        expect(mock_ct).to receive(:fields=)
        expect(mock_ct).to receive(:save)

        described_class.new(nil, mock_ct).save
      end
    end

    it '#remove_field' do
      mock_ct = Object.new
      mock_fields = Object.new

      expect(mock_ct).to receive(:fields) { mock_fields }
      expect(mock_fields).to receive(:destroy).with('foo')

      described_class.new(nil, mock_ct).remove_field('foo')
    end

    describe '#id' do
      it 'can set the id' do
        subject.id = 'foo_ct'
        expect(subject.id).to eq 'foo_ct'
      end

      it 'when saving, defined id will be used' do
        subject.id = 'foo_ct'

        expect_any_instance_of(::Contentful::Management::ClientContentTypeMethodsFactory).to receive(:create).with(
          id: 'foo_ct',
          name: subject.name,
          fields: subject.fields
        )

        subject.save
      end
    end

    describe '#field' do
      it 'snake cases field id' do
        field = subject.field('Foo Test', :symbol)

        expect(field.id).to eq('foo_test')
        expect(field.name).to eq('Foo Test')
      end

      it 'regular field' do
        field = subject.field('foo', :symbol)

        expect(field.id).to eq('foo')
        expect(field.name).to eq('foo')
        expect(field.type).to eq('Symbol')
        expect(field.link_type).to eq(nil)
        expect(field.items).to eq(nil)
      end

      it 'converts :string to :symbol field' do
        field = subject.field('foo', :string)

        expect(field.type).to eq('Symbol')
      end

      it 'link field' do
        field = subject.field('foo', :entry_link)

        expect(field.id).to eq('foo')
        expect(field.name).to eq('foo')
        expect(field.type).to eq('Link')
        expect(field.link_type).to eq('Entry')
        expect(field.items).to eq(nil)
      end

      it 'array field' do
        field = subject.field('foo', :asset_array)

        expect(field.id).to eq('foo')
        expect(field.name).to eq('foo')
        expect(field.type).to eq('Array')
        expect(field.link_type).to eq(nil)

        items = field.items

        expect(items).to be_a(Contentful::Management::Field)
        expect(items.type).to eq('Link')
        expect(items.link_type).to eq('Asset')
      end

      it 'fails on unknown type' do
        expect { subject.field('foo', :bar) }.to raise_error ContentfulModel::Migrations::InvalidFieldTypeError
      end
    end

    describe '#fields' do
      describe 'from a new content type' do
        it 'starts empty' do
          expect(subject.fields).to eq([])
        end

        it 'adds fields when you call :field' do
          expect(subject.fields.size).to eq(0)

          subject.field('foo', :text)

          expect(subject.fields.size).to eq(1)
          expect(subject.fields[0]).to be_a(Contentful::Management::Field)
        end
      end

      describe 'from an existing content type' do
        before do
          @mock_ct = Object.new
          allow(@mock_ct).to receive(:id) { 'foo' }
          allow(@mock_ct).to receive(:fields) { [Contentful::Management::Field.new] }
        end

        it 'returns previously existing fields' do
          subject = described_class.new(nil, @mock_ct)

          expect(subject.fields.size).to eq(1)
        end

        it 'appends fields to existing fields' do
          subject = described_class.new(nil, @mock_ct)

          expect(subject.fields.size).to eq(1)

          subject.field('foo', :text)

          expect(subject.fields.size).to eq(2)
        end
      end
    end
  end
end
