require 'spec_helper'

class MockMigration
  include ContentfulModel::Migrations::Migration
end

describe ContentfulModel::Migrations::Migration do
  subject { MockMigration.new }

  before do
    @mock_content_type = Object.new
    @mock_field = Object.new
    allow(ContentfulModel::Migrations::ContentTypeFactory).to receive(:find).with('ct_id') { @mock_content_type }
    allow(@mock_content_type).to receive(:save) { @mock_content_type }
    allow(@mock_content_type).to receive(:publish)
    allow(@mock_content_type).to receive(:field).with('name', :type) { @mock_field }
    allow(@mock_content_type).to receive(:remove_field).with('name')
  end

  describe "#create_content_type" do
    it 'creates content type' do
      expect(ContentfulModel::Migrations::ContentTypeFactory).to receive(:create)

      subject.create_content_type('foo')
    end
  end

  describe '#add_content_type_field' do
    it 'creates field' do
      expect(@mock_content_type).to receive(:field)

      subject.add_content_type_field('ct_id', 'name', :type)
    end

    it 'publishes content type' do
      expect(@mock_content_type).to receive(:publish)

      subject.add_content_type_field('ct_id', 'name', :type)
    end

    it 'saves content type' do
      expect(@mock_content_type).to receive(:save)

      subject.add_content_type_field('ct_id', 'name', :type)
    end

    it 'yields content type' do
      expect(@mock_field).to receive(:validations=)

      subject.add_content_type_field('ct_id', 'name', :type) do |field|
        field.validations = []
      end
    end
  end

  describe '#remove_content_type_field' do
    it 'removes field' do
      expect(@mock_content_type).to receive(:remove_field).with('name')

      subject.remove_content_type_field('ct_id', 'name')
    end

    it 'publishes content type' do
      expect(@mock_content_type).to receive(:publish)

      subject.remove_content_type_field('ct_id', 'name')
    end

    it 'saves content type' do
      expect(@mock_content_type).to receive(:save)

      subject.remove_content_type_field('ct_id', 'name')
    end
  end
end
