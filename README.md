# ContentfulModel

This is a thin wrapper around the [Contentful Delivery SDK](https://github.com/contentful/contentful.rb) and [Contentful Management SDK](https://github.com/contentful/contentful-management.rb) api client libraries.

It allows you to inherit from `ContentfulModel::Base` and specify the content type id, and optionally, fields to coerce in a specific way.

Note that this library doesn't allow you to save changes to your models back to Contentful. We need to use the Contentful Management API for that. Pull requests welcome!

## What is Contentful?

[Contentful](https://www.contentful.com) provides a content infrastructure for digital teams to power content in websites, apps, and devices. Unlike a CMS, Contentful was built to integrate with the modern software stack. It offers a central hub for structured content, powerful management and delivery APIs, and a customizable web app that enable developers and content creators to ship digital products faster.

# Usage

## Configure ContentfulModel

Configure ContentfulModel with a block. In a Rails app this is best done in an initializer:

```
ContentfulModel.configure do |config|
  config.access_token = "your access token in here" # Required
  config.preview_access_token = "your preview token in here" # Optional - required if you want to use the preview API
  config.management_token = "your management token in here" # Optional - required if you want to update or create content
  config.space = "your space id in here" # Required
  config.environment = "master" # Optional - defaults to 'master'
  config.default_locale = "en-US" # Optional - defaults to 'en-US'
  config.options = { # Optional
    # Extra options to send to the Contentful::Client and Contentful::Management::Client
    # See https://github.com/contentful/contentful.rb#configuration

    # Optional:
    # Use `delivery_api` and `management_api` keys to limit to what API the settings
    # will apply. Useful because Delivery API is usually visitor facing, while Management
    # is used in background tasks that can run much longer. For example:
    delivery_api: {
      timeout_read: 6
    },
    management_api: {
      timeout_read: 100
    }
  }
end

```

It is important to set the `default_locale` to match the one set in your Contentful settings, otherwise the fields will have no content.

## Create a model class

Create a class which inherits from `ContentfulModel::Base`.

```
class Foo < ContentfulModel::Base
   self.content_type_id = "content type id for this model"
end
```

ContentfulModel takes care of setting instance variables for each field in your model. You can optionally coerce fields to the right format - for example dates:

```
class Foo < ContentfulModel::Base
   self.content_type_id = "content type id for this model"

   coerce_field birthday: :Date
   coerce_field store_id: :Integer
end
```
See a list of the available coercions [here](https://github.com/contentful/contentful.rb/blob/master/lib/contentful/field.rb#L9-L22).

## Queries and Searching
ContentfulModel allows you to chain queries, like ActiveRecord. The options are as follows.

### `first()`
Returns the first entry for your content type.

### `all()`
Returns all entries of a particular content type. Requires `load()` to be called at the end of the chain.

```
Foo.all.load
```

### `params([hash])`
Allows you to send any arbitrary query to Contentful.

### `offset([integer])`
(Also aliased as `skip()`). Allows you to specify an offset from the start of the returned set. Requires `load()` at the end of the chain.

```
Foo.all.offset(2).load
```

### `limit([integer])`
Limits the amount of returned entries (minimum 1, maximum 1000, default is 100).

### `paginate(page = 1, per_page = 100, order_field = 'sys.updatedAt', additional_options = {})`
Fetches the requested entry page. `additional_options` allows you to send more specific query parameters.

### `each_page(per_page = 100, order_field = 'sys.updatedAt', additional_options = {}, &block)`
Allows you to execute the given block over each page for your content type. It automatically does pagination for you.

### `each_entry(per_page = 100, order_field = 'sys.updatedAt', additional_options = {}, &block)`
Same as `each_page` but iterates through every entry. It automatically does pagination for you.

### `find([id])`
Returns the entry of the content type you've called, matching the id you passed into the `find()` method. _Does not_ require `load()`.

```
Foo.find("someidfromcontentful")
```

### `find_by([hash])`
Accepts a hash of options to include in the search, as similar as possible to ActiveRecord version. __Note__ that this doesn't work (and will throw an error) on fields which need the full-text search. This needs fixing. Requires load() to be called at the end of the chain.

```
Foo.find_by(someField: [searchquery1, searchquery2], someOtherField: "bar").load
```

You'll see from the example above that it accepts an array of search terms which will invoke an 'in' query.

### `params({object})`
Includes the specified parameters in the Contentful API call.

```
Foo.all.params({"include" => 3}).load
```

### `locale([string])`
Fetches the entries for a specific locale code, or all if `'*'` is sent.

### `load_children([integer])`
Fetches nested links to the specified level.

```
Foo.load_children(3).load
```

### `order([string, hash or array of strings])`
Sets the order for the executed query.

For example, to sort in reverse chronological order: `order(createdAt: :desc)`

## Associations
You can specify associations between models in a similar way to ActiveRecord. There are some differences, though, so read on.

### There's no `belongs_to`
Contentful allows you to create relationships between content types - so a parent content type can have one or many child entries. You can (and probably should) validate the content types in your child field - for example, a 'page' might have one entry of content type 'template'.

However: it's not possible to assign an entry only once - so that means that every child entry might belong to more than one parent. So there isn't a `belongs_to` method because it wouldn't make any sense. Use `belongs_to_many` instead.

(If you happen to accidentally declare `belongs_to` on a model, you'll get a `NotImplementedError`.

### `has_one`

Define a `has_one` relationship on a parent model, just like you would for ActiveRecord. For example:


A simple example:

```
class Article < ContentfulModel::Base
    has_one :author #author is the name of the field in contentful
end
```

A more complex example, with a child model class that doesn't follow the name of the field on the parent.

```
class Page < ContentfulModel::Base
    has_one :template, class_name: "PageTemplate", inverse_of: :page #template is the name of the field in contentful
end
```

`Page` will now have a method called `template` which returns the PageTemplate you have assigned in Contentful. Similarly, `Article` will have a method called `author` which returns the Author.

Provided you've properly set up `belongs_to_many` on the other end of the relationship, you'll have a utility method on the child model called `page()`. This is the entity *which loaded the child*. In most cases this is pretty useful.

### `has_many`
Using `has_many` is conceptually identical to `has_one`, instead of a single entity you'll receive an array.

### `belongs_to_many`
Use `belongs_to_many` on the other end of a `has_one` or `has_many` relationship.

Our Article class above has a child called Author. The author will probably belong to many articles.

(note: you could model this particular example the other way around)

```
class Author < ContentfulModel::Base
    belongs_to_many :articles
end
```

Using `belongs_to_many` gives you a couple of useful methods on the child. Using the Article example above:

* `article()` - this is the parent article which called the child author. If you call Author.find() explicitly, this will be nil
* `articles()` - this requires an API call, and will return a collection of articles which has this author as a child

### `has_many_nested` - using self-referential content types to create a tree
This is a departure from the classic ActiveRecord syntax here, but pretty useful. There are probably situations where you want to have a content type which has children of the same type. For example, a [Error](http://www.errorstudio.co.uk) we often has a tree of pages for a website.

In this example let's assume you have a Page content type, which has a field called childPages in Contentful - this is referenced as child_pages in ContentfulModel.

Here's how you'd set it up:

```
class Page < ContentfulModel::Base
    has_many_nested :child_pages
end
```

This calls `has_many` and `belongs_to_many` on the Page model, and gives you some useful instance methods.

* `parent()` - the parent of the current Page
* `children()` - the children of the current Page
* `has_children?()` - returns `true` or `false` depending on whether this page has children
* `root?()` - returns `true` or `false` depending on whether this Page is a root page (i.e. no parents)
* `root()` - returns the root page, from this page's point of view
* `ancestors()` - an `Enumerable` you can iterate over to get all the ancestors. Surprisingly quick.
* `nested_children` - returns a nested hash of children
* `nested_children_by(:field)` - takes the name of the field you want to return, and returns a hash of nested children by the field you specify. E.g. `nested_children_by(:slug)`.
* `find_child_path_by(:field, "thing-to-search")` - returns an array of the child's parents. Useful for determining the ancestors of an entity you've called directly.
* `all_child_paths_by(:field)` - return a 2d array of paths for all children. One of a couple of ways you can set up navigation.

From this, you can:

* Build up a tree from calls to the top-level entity (e.g. a navigation tree)
* Reverse-iterate up the tree from a given page (e.g. breadcrumbs)

#### Defining a root page
You can pass an optional second parameter into `has_many_nested` which means the class knows how to find its root:

```
class Page < ContentfulModel::Base
    has_many_nested :child_pages, root: -> { Page.find("some_id").first }
end
```

Adding this second parameter defines a method called `root_page` on the class, so you can get the root easily. Your proc needs to return one object.

## Preview mode
You might want to hit the preview API. Our [contentful_rails](https://github.com/errorstudio/contentful_rails) gem uses it, for example.

Provided you've set a `preview_api_token` in the configuration block, it's dead easy. Just set `ContentfulModel.use_preview_api = true` before making calls.

## Validations

Validations are a simple way to check content before sending it back to the server on `#save`.
This is often useful when working on organizations with heavy CMA traffic, in which by using validations previous to hitting the API,
we can ensure that the API will only be hit when a successful request can be made.

There is a special case of validations, that are run when content is being loaded when running `::load`,
failing those validations will filter out that content from the response,
you can transform any of the following validations to an `:on_load` validation by appending `on_load: true` on the `::validate` filter.
This validations will also be run before `#save`.

You can skip validations on `#save` by calling it as `my_entry.save(true)` or `my_entry.save!`.

### Inline Validations
Inline validations are a useful shorthand for creating validations, they can be added as a lambda function or a block. In any of the cases,
they must receive a single parameter and return a boolean.

```ruby
class Product < ContentfulModel::Base
  # validation with a lambda
  validate :price_is_positive, -> (e) { e.price > 0 }

  # validation with a block
  validate :category_is_not_empty do |e|
    !e.category.empty?
  end

  # :on_load validation
  validate :name_longer_than_3_characters, -> (e) { e.name.size > 3 }, on_load: true
end
```

The above example will run the `:price_is_positive` and `:category_is_not_empty` only on `#save` and `:name_is_longer_than_3_characters` both on `::load` and `#save`.

When an inline validation fails, an error with the following structure will be added to `#errors`: `"#{validation_alias}: validation not met"`.

### Class and Object based Validations
If inline validations aren't flexible enough for your needs, you can create class and object based validations.
These validations can return multiple errors. They must define a `#validate(entry)` method, which must return an array of errors or an empty array.

Class validations are useful when the validation class doesn't require setup. For example:

```ruby
class NameValidation
  def validate(entry)
    errors = []
    errors << "Name not long enough" if entry.name.size < 3
    errors << "Name not capitalized" if entry.name != entry.name.capitalize
    errors
  end
end

class Post < ContentfulModel::Base
  validate_with NameValidation
end
```

Object validations are just like Class validations, with the exception that they can define a constructor in order to parameterize them. For example:

```ruby
class FieldLengthValidation
  def initialize(field_name, length)
    @field_name = field_name
    @length = length
  end

  def validate(entry)
    errors = []
    errors << "#{@field_name} less than #{@length} character/s long" if entry.public_send(@field_name).size < @length
    errors
  end
end

class Post < ContentfulModel::Base
  validate_with FieldLengthValidation.new(:title, 10)
  validate_with FieldLengthValidation.new(:content, 200)
end
```

With these validations, you can define more complex and combined validations for your models.
As with Inline validations, you can enable them to run on `::load` by appending `on_load: true` after the `::validate_with` filter.

### PresenceOf - Suppressing unvalidated content in preview
Draft content doesn't include values which didn't pass the validations on responses.
This content wouldn't be able to be saved on the CMA, and the WebApp keeps the state but doesn't save it to the API.

Therefore, when using the content, we require a way to make sure that those values are present in the entries we intend to display,
and be able to filter out entries that do not contain those values, so a filter with an ActiveRecord-like sintax is provided.

This validation is always run `:on_load`

```ruby
class Page < ContentfulModel::Base
  validates_presence_of :slug, :title, :some_other_vital_field
end
```

If you've defined this in a class, any queries to the API will filter out entities which aren't valid. This applies to both relations (where you might get a collection), or searches.

## Returning nil for fields which aren't defined

If an object is valid, but has content missing from a field, the Contentful API doesn't return the field. That means that you have to check manually for its existence to avoid raising a `NoMethodError`.

We decided it would be nice to be able to declare that certain fields should return nil, rather than raising an error. You can do that as follows:

```ruby
class Page
  return_nil_for_empty :content, :excerpt
end
```

This means you can check for `content.nil?` instead of rescueing from an error. Much nicer.

## Updating Content

With the newly introduced support for Contentful's CMA, you can now create and update entries

### Creating entries

You can create entries by doing:

```ruby
MyModel.create(my_field: 'some value')
```

### Saving entries

Just call the `#save` method on your entries and it will get updated on Contentful

```ruby
my_model.my_field = 'other value'

my_model.save
```

### Publishing entries

You can also publish directly by calling `#publish` on your models.

```ruby
my_model.publish
```

## Assets

Assets are wrapped in a `ContentfulModel::Asset` class, which has shorthand methods for all of the Image API options.

```
url = my_asset.resize(10, 20).rounded_corners(30).png_8bit.thumbnail_focused_on('face').load
```

You can also perform searches on assets.

```
assets = Asset.all('sys.updatedAt[gte]' => 2.days.ago)

asset = Asset.find('asset_id')
```

## Content Migrations

You can also create and alter Content Types with the Migrations module.

You can use it as follows:

```ruby
class CreateFooContentType < ActiveRecord::Migration
  include ContentfulModel::Migrations::Migration

  def up
    create_content_type('foo') do |ct|
      ct.field('bar', :symbol)
      ct.field('baz', :date)
    end

    add_content_type_field 'foo', 'foobar', :integer
  end

  def down
    remove_content_type_field 'foo', 'foobar'
  end
end
```

# To Do
There are quite a few outstanding tasks:

* Some tests :-)

# Licence
MIT - please see MIT-LICENCE in this repo.

# Contributing
Please feel free to contribute. We would love your input.

* Fork the repo
* Make changes
* Commit and make a PR :-)
