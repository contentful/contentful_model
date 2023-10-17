$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'contentful_model/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'contentful_model'
  s.version     = ContentfulModel::VERSION
  s.authors     = ['Contentful GmbH (David Litvak Bruno)', 'Error Creative Studio']
  s.email       = ['david.litvak@contentful.com', 'hosting@errorstudio.co.uk']
  s.homepage    = 'https://github.com/contentful/contentful_model'
  s.summary     = 'An ActiveModel-like wrapper for the Contentful SDKs'
  s.description = 'An ActiveModel-like wrapper for the Contentful SDKs'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'contentful', '~> 2.7'
  s.add_dependency 'contentful-management', '~> 3.8'

  s.add_dependency 'redcarpet'
  s.add_dependency 'activesupport'

  s.add_development_dependency 'vcr'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-rubocop'
  s.add_development_dependency 'guard-yard'
  s.add_development_dependency 'webmock', '>= 3.7.6'
  s.add_development_dependency 'tins', '~> 1.6.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rubocop', '~> 0.49.0'
  # listen v3 requires ruby >= 2.2.7 which fails on travis with 2.2.0
  # so we need to stay on v2
  s.add_development_dependency 'listen', '~> 2'
end
