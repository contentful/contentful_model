require 'spec_helper'

class MockMigration
  include ContentfulModel::Migrations::Migration
end

describe ContentfulModel::Migrations::Migration do
  subject { MockMigration.new }

  it '#create_content_type' do
    expect(ContentfulModel::Migrations::ContentTypeFactory).to receive(:create)

    subject.create_content_type('foo')
  end

  it '#add_content_type_field' do
    mock_ct = Object.new
    allow(ContentfulModel::Migrations::ContentTypeFactory).to receive(:find).with('ct_id') { mock_ct }
    expect(mock_ct).to receive(:field).with('name', :type)
    expect(mock_ct).to receive(:save) { mock_ct }
    expect(mock_ct).to receive(:publish)

    subject.add_content_type_field('ct_id', 'name', :type)
  end

  it '#remove_content_type_field' do
    mock_ct = Object.new
    allow(ContentfulModel::Migrations::ContentTypeFactory).to receive(:find).with('ct_id') { mock_ct }
    expect(mock_ct).to receive(:remove_field).with('field_id')
    expect(mock_ct).to receive(:save) { mock_ct }
    expect(mock_ct).to receive(:publish)

    subject.remove_content_type_field('ct_id', 'field_id')
  end
end
