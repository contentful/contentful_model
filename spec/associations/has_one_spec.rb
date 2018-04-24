require 'spec_helper'

class HasOneTestModel < ContentfulModel::Base
  self.content_type_id = 'hasOneTestModel'

  has_one :test_model
end

describe ContentfulModel::Associations::HasOne do
  before :each do
    ContentfulModel.configure do |c|
      c.space = 'a22o2qgm356c'
      c.access_token = '60229df5876f14f499870d0d26f37b1323764ed637289353a5f74a5ea190c214'
      c.entry_mapping = {}
    end

    HasOneTestModel.add_entry_mapping
    TestModel.add_entry_mapping
  end

  it 'resolves children references' do
    vcr('association/has_one') {
      parent = HasOneTestModel.first

      expect(parent).to be_a HasOneTestModel
      expect(parent.name).to eq 'Has One - Parent 1'

      expect(parent.test_model).to be_a TestModel
      expect(parent.test_model.name).to eq 'Has One - Child'
    }
  end
end
