require 'spec_helper'

class MockValidatableNoFields
  include ContentfulModel::Validations
end

class MockValidatable
  include ContentfulModel::Validations

  attr_reader :fields

  def initialize(fields = [])
    @fields = fields
    fields.each do |f|
      define_singleton_method f do
        "#{f}_value"
      end
    end
  end
end

class MockValidatableWithAdditionalValidation < MockValidatable
  validates_presence_of 'foo'
end

describe ContentfulModel::Validations do
  let(:validatable) { MockValidatable.new }
  let(:non_validatable) { MockValidatableNoFields.new }
  let(:validatable_with_fields) { MockValidatable.new(['foo']) }
  let(:validatable_with_validations) { MockValidatableWithAdditionalValidation.new }

  describe 'class methods' do
    describe '::validations' do
      it 'is nil by default' do
        expect(validatable.class.validations).to eq nil
      end

      it 'is an array of validations' do
        expect(validatable_with_validations.class.validations).to be_a Array
        expect(validatable_with_validations.class.validations.size).to eq 1
      end
    end
  end

  describe 'instance methods' do
    describe '#validate' do
      it 'returns false and sets error if its not an entry (aka. has no fields)' do
        expect(non_validatable.validate).to be_falsey
        expect(non_validatable.errors).to eq ["Entity doesn't respond to the fields() method"]
        expect(non_validatable.valid?).to be_falsey
        expect(non_validatable.invalid?).to be_truthy
      end

      it 'returns false and sets error if validation does not pass' do
        expect(validatable_with_validations.validate).to be_falsey
        expect(validatable_with_validations.errors).to eq ["foo is required"]
        expect(validatable_with_validations.valid?).to be_falsey
        expect(validatable_with_validations.invalid?).to be_truthy
      end

      it 'returns true if validations pass' do
        ok_valitable = MockValidatableWithAdditionalValidation.new(['foo'])

        expect(ok_valitable.validate).to be_truthy
        expect(ok_valitable.errors).to be_empty
        expect(ok_valitable.valid?).to be_truthy
        expect(ok_valitable.invalid?).to be_falsey
      end
    end
  end
end
