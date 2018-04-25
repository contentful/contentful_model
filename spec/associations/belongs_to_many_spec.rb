require 'spec_helper'

class BelongsToManyParent < ContentfulModel::Base
  self.content_type_id = 'belongsToManyParent'

  has_many :children, class_name: 'BelongsToManyChild'
end

class BelongsToManyChild < ContentfulModel::Base
  self.content_type_id = 'belongsToManyChild'

  belongs_to_many :parents, inverse_of: :children, class_name: 'BelongsToManyParent'
end

describe ContentfulModel::Associations::BelongsToMany do
  before :each do
    ContentfulModel.configure do |c|
      c.space = 'a22o2qgm356c'
      c.access_token = '60229df5876f14f499870d0d26f37b1323764ed637289353a5f74a5ea190c214'
      c.entry_mapping = {}
    end

    BelongsToManyParent.add_entry_mapping
    BelongsToManyChild.add_entry_mapping
  end

  it 'defines reverse relationship' do
    vcr('association/belongs_to_many') {
      child = BelongsToManyChild.first
      expect(child.name).to eq 'BelongsToMany - Child'

      expect(child.parents).to be_a ::Array
      expect(child.parents.size).to eq 2
      expect(child.parents.first).to be_a BelongsToManyParent
      expect(child.parents.first.name).to eq 'BelongsToMany - Parent 1'
    }
  end
end
