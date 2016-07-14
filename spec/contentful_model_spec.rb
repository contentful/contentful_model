require 'spec_helper'

describe ContentfulModel do
  subject { described_class }

  describe 'class methods' do
    it '::configure' do
      subject.configure do |config|
        config.access_token = 'foo'
        config.preview_access_token = 'bar'
        config.management_token = 'baz'
        config.space = 'foo_space'
        config.default_locale = 'en-US'
        config.entry_mapping = {}
      end

      expect(subject.configuration.access_token).to eq 'foo'
      expect(subject.configuration.preview_access_token).to eq 'bar'
      expect(subject.configuration.management_token).to eq 'baz'
      expect(subject.configuration.space).to eq 'foo_space'
      expect(subject.configuration.default_locale).to eq 'en-US'
      expect(subject.configuration.entry_mapping).to eq({})
    end
  end
end
