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

class BestFriendValidation
  def validate(entry)
    return ['Best Friend is not happycat'] unless entry.best_friend.try(:id) == 'happycat'
    []
  end
end

class LivesValidation
  def initialize(lives)
    @lives = lives
  end

  def validate(entry)
    return ["Lives are not #{@lives}"] unless entry.lives == @lives
    []
  end
end

class ValidationsCat < ContentfulModel::Base
  self.content_type_id = 'cat'

  # validation lambda
  validate :name, -> (e) { e.name == 'Nyan Cat' }, on_load: true

  # validation block
  validate :id, on_load: true do |e|
    e.id == 'nyancat'
  end

  # validation class
  validate_with BestFriendValidation, on_load: true

  # validation object
  validate_with LivesValidation.new(1337), on_load: true

  # validation only on save
  validate :name, -> (e) { e.name == 'foobar' }

  # presence validation
  validates_presence_of :likes
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
        ok_validatable = MockValidatableWithAdditionalValidation.new(['foo'])

        expect(ok_validatable.validate).to be_truthy
        expect(ok_validatable.errors).to be_empty
        expect(ok_validatable.valid?).to be_truthy
        expect(ok_validatable.invalid?).to be_falsey
      end
    end
  end

  describe 'integration' do
    before :each do
      ContentfulModel.configure do |config|
        config.space = 'cfexampleapi'
        config.access_token = 'b4c0n73n7fu1'
        config.entry_mapping = {}
      end

      ValidationsCat.client = nil
    end

    it 'can have many kinds of validations' do
      expect(ValidationsCat.validations.size).to eq 5
      expect(ValidationsCat.save_validations.size).to eq 1
    end

    it 'can pass all validations' do
      vcr('nyancat') {
        nyancat = ValidationsCat.find('nyancat')
        expect(nyancat.validate).to be_truthy
        expect(nyancat.invalid?).to be_falsey
        expect(nyancat.valid?).to be_truthy
        expect(nyancat.errors).to be_empty
      }
    end

    it 'can validate save validations' do
      vcr('nyancat') {
        nyancat = ValidationsCat.find('nyancat')

        expect(nyancat.validate(true)).to be_falsey
        expect(nyancat.invalid?(true)).to be_truthy
        expect(nyancat.valid?(true)).to be_falsey
        expect(nyancat.errors.size).to eq 1
      }
    end

    it 'can fail a validation' do
      vcr('nyancat') {
        nyancat = ValidationsCat.find('nyancat')
        nyancat.name = 'foobar'
        expect(nyancat.validate).to be_falsey
        expect(nyancat.invalid?).to be_truthy
        expect(nyancat.errors).to eq ["name: validation not met"]
      }
    end

    it 'can fail multiple validations' do
      vcr('nyancat') {
        nyancat = ValidationsCat.find('nyancat')
        nyancat.name = 'foobar'
        nyancat.lives = 1000
        nyancat.best_friend = nil
        nyancat.sys[:id] = 'foo'
        nyancat.likes = nil

        expect(nyancat.validate).to be_falsey
        expect(nyancat.errors).to match_array [
          "name: validation not met",
          "Lives are not 1337",
          "Best Friend is not happycat",
          "id: validation not met",
          "likes is required"
        ]
      }
    end
  end
end
