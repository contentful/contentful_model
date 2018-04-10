require_relative 'belongs_to'
require_relative 'belongs_to_many'
require_relative 'has_many'
require_relative 'has_one'
require_relative 'has_many_nested'

module ContentfulModel
  # A module to map relationships, a little like ActiveRecord::Relation
  # This is necessary because Contentful::Link classes are not 2-way, so you can't
  # get the parent from a child.
  module Associations
    def self.included(base)
      base.include HasMany
      base.include HasOne
      base.include BelongsTo
      base.include BelongsToMany
      base.include HasManyNested
    end
  end
end
