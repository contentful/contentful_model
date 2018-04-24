require 'spec_helper'

class HasManyTestModel < ContentfulModel::Base
  self.content_type_id = 'hasManyTestModel'

  has_many :test_models
end

describe ContentfulModel::Associations::HasOne do
  before :each do
    ContentfulModel.configure do |c|
      c.space = 'a22o2qgm356c'
      c.access_token = '60229df5876f14f499870d0d26f37b1323764ed637289353a5f74a5ea190c214'
      c.entry_mapping = {}
    end

    HasManyTestModel.add_entry_mapping
    TestModel.add_entry_mapping
  end

  it 'resolves children references' do
    vcr('association/has_many') {
      parent = HasManyTestModel.first

      expect(parent).to be_a HasManyTestModel
      expect(parent.name).to eq 'Has Many - Parent 1'

      expect(parent.test_models).to be_a ::Array
      expect(parent.test_models.size).to eq 2
      expect(parent.test_models.first.name).to eq 'Has Many - Child 1'
    }
  end
end
