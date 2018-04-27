# CHANGELOG

This Changelog has been introduced after the 0.1.7 release by @errorstudio.
Since then, @contentful has taken ownership. This changelog will start reflecting
changes from that point onwards.

## Master

### Added

* Added `::validate_with` and `::validate` methods for more complex validations
* Added `#hash` and `#eql?` to `ContentfulModel::Base` for equality and set operations [#65](https://github.com/contentful/contentful_model/issues/65)
* Added `#id` and `#id=` to `ContentfulModel::Migrations::ContentType` to allow to set a custom ID [#80](https://github.com/contentful/contentful_model/issues/80)
* Added default ID for content types created using migrations, to be the `camelCased` version of the name, replicating the Web App [#80](https://github.com/contentful/contentful_model/issues/80)
* Added `#paginate` query to allow pagination [#79](https://github.com/contentful/contentful_model/pull/79)
* Added tests for user defined methods and nested classes [#74](https://github.com/contentful/contentful_model/issues/74)
* Added automated include discovery when using explicit relationship declarations [#85](https://github.com/contentful/contentful_model/issues/85)
* Added support for environments
* Added `#each_page` and `#each_entry` to automatically paginate entries
* Added `Asset` wrapper class with search and Image API extensions [#3](https://github.com/contentful/contentful_model/issues/3)

### Fixed

* Setters and Getters now work for current locale instead of only default locale
* Management SDK now properly raises errors and works properly with localized content
* Queries now properly returns `::Contentful::Array` instead of `::Array` instances [#67](https://github.com/contentful/contentful_model/issues/67)
* Queries now allow multiple fields for `find_by` and also works with `sys` fields [#49](https://github.com/contentful/contentful_model/issues/49)
* Queries now do not share state any more, interface remained the same [#94](https://github.com/contentful/contentful_model/issues/94)
* Queries using `find_by` can now also request `sys` fields without having to specify always the `sys.` prefix
* `return_nil_for_empty` no longer throws an error [#73](https://github.com/contentful/contentful_model/issues/73)
* `belongs_to_many` now uses the `links_to_entry` parameter and greatly simplifies the code
* `has_many_nested` now properly works and does extra queries only when required

### Changed

* Updated to CDA SDK 2.x
* Updated to CMA SDK 2.x
* Updated Specs to run mostly against real data instead of mocks
* Validations are now run by default before `#save`
* Removed `require_all` dependency [#95](https://github.com/contentful/contentful_model/issues/95)
* `ChainableQueries` module removed, behaviour now moved to `Queries` and `Query`. [#94](https://github.com/contentful/contentful_model/issues/94)
* `has_children?` for `has_many_nested` was renamed to `children?`
* Updated code to follow our style guide
* `belongs_to_many` now doesn't support `inverse_of`

## 0.2.0

### Added
* Added CMA Integration
* Added Specs for all major components
* Added Content Model Migrations
* Added Locale Search [#27](https://github.com/contentful/contentful_model/issues/27)

### Fixed
* Fixed getter method resolution

## 0.1.7 (and previous)

* CDA Integration with Query Capabilities
* Preview API Integration
