module ContentfulModel
  class AssociationError < StandardError; end
  class VersionMismatchError < StandardError; end
  class AttributeNotFoundError < NoMethodError; end
end
