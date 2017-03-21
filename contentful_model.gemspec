$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "contentful_model/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "contentful_model"
  s.version     = ContentfulModel::VERSION
  s.authors     = ["Error Creative Studio"]
  s.email       = ["hosting@errorstudio.co.uk"]
  s.homepage    = "https://github.com/errorstudio/contentful_model"
  s.summary     = "A thin wrapper for Contentful gem"
  s.description = "A wrapper around the Contentful gem to give you a base class to inherit your models from"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "contentful"
  s.add_dependency "contentful-management", '~> 1.0'
  s.add_dependency "redcarpet"
  s.add_dependency "activesupport"
  s.add_dependency 'require_all'

  s.add_development_dependency "vcr"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "webmock"
  s.add_development_dependency "simplecov"
end
