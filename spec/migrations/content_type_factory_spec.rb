require 'spec_helper'

describe ContentfulModel::Migrations::ContentTypeFactory do
  describe '::create' do
    before do
      @mock_ct = Object.new
      allow(ContentfulModel::Migrations::ContentType).to receive(:new) { @mock_ct }
      expect(@mock_ct).to receive(:save)
    end

    it 'saves it' do
      described_class.create('foo')
    end

    it 'calls :field for each field sent' do
      expect(@mock_ct).to receive(:field).with(:bar, :symbol)
      expect(@mock_ct).to receive(:field).with(:baz, :text)

      described_class.create('foo', bar: :symbol, baz: :text)
    end

    it 'yields it' do
      expect(@mock_ct).to receive(:field).with(:bar, :symbol)

      described_class.create('foo') do |ct|
        ct.field(:bar, :symbol)
      end
    end
  end

  it '::find' do
    ContentfulModel.configure { |config| config.space = 'space_id' }
    mock_client = Object.new

    allow_any_instance_of(ContentfulModel::Management).to receive(:content_types).with('space_id', 'master') { mock_client }
    expect(mock_client).to receive(:find).with('ct_id')

    result = described_class.find('ct_id')
    expect(result).to be_a(ContentfulModel::Migrations::ContentType)
  end
end
