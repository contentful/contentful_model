require 'spec_helper'

describe ContentfulModel::Associations::BelongsTo do
  before :each do
    ContentfulModel.configure do |c|
      c.default_locale = 'en-US'
      c.access_token = '4d0f55d940975f78139daae5d965b463c0816e88ad16062d2c1ee3d6cb930521'
      c.space = 'facgnwwgj5fe'
      c.entry_mapping = {}
    end
  end

  it 'is not implemented - on purpose' do
    expect {
      class BelongsToCat < ContentfulModel::Base
        self.content_type_id = 'cat'

        belongs_to :best_friend, class: Cat
      end
    }.to raise_error "Contentful doesn't have a singular belongs_to relationship. Use belongs_to_many instead."
  end
end
