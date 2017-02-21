# ContentfulModel

This is a thin wrapper around the [Contentful Delivery SDK](https://github.com/contentful/contentful.rb) and [Contentful Management SDK](https://github.com/contentful/contentful-management.rb) api client libraries.

It allows you to inherit from `ContentfulModel::Base` and specify the content type id, and optionally, fields to coerce in a specific way.

Note that this library doesn't allow you to save changes to your models back to Contentful. We need to use the Contentful Management API for that. Pull requests welcome!

## What is Contentful?

[Contentful](https://www.contentful.com) is a content management platform for web applications, mobile apps and connected devices. It allows you to create, edit & manage content in the cloud and publish it anywhere via powerful API. Contentful offers tools for managing editorial teams and enabling cooperation between organizations.

# Usage

## Configure ContentfulModel

Configure ContentfulModel with a block. In a Rails app this is best done in an initializer:

```
ContentfulModel.configure do |config|
  config.access_token = "your access token in here"
  config.preview_access_token = "your preview token in here"
  config.management_token = "your management token in here"
  config.space = "your space id in here"
  config.default_locale = "en-US"
  config.options = {
    #extra options to send to the Contentful::Client
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

   coerce_field birthday: :date
   coerce_field store_id: :integer
end
```

## Queries and Searching
ContentfulModel allows you to chain queries, like ActiveRecord. The options are as follows.

### `all()`
Returns all entries of a particular content type. Requires `load()` to be called at the end of the chain.

```
Foo.all.load
```

### `offset([integer])`
(Also aliased as `skip()`). Allows you to specify an offset from the start of the returned set. Requires `load()` at the end of the chain.

```
Foo.all.offset(2).load
```

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

## Associations
You can specify associations between models in a similar way to ActiveRecord. There are some differences, though, so read on.

### There's no `belongs_to`
Contentful allows you to create relationships between content types - so a parent content type can have one or many child entries. You can (and probably should) validate the content types in your child field - for example, a 'page' might have one entry of content type 'template'.

However: it's not possible to assign an entry only once - so that means that every child entry might belong to more than one parent. So there isn't a `belongs_to` method because it wouldn't make any sense. Use `belongs_to_many` instead.

(If you happen to accidentally declare `belongs_to` on a model, you'll get a `NotImplementedError`.

### `has_one`
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
Using `has_many` is conceptually identical to `has_one`, so there isn't much to say here.

### `belongs_to_many`
Use `belongs_to_many` on the other end of a `has_one` or `has_many` relationship.

Our Article class above has a child called Author. The author will probably belong to many articles.

(note: you could model this particular example the other way around)

```
class Author < ContentfulModel::Base
    belongs_to_many :articles
end
```

Our Page class above has a method called template. This returns a PageTemplate class; we set the inverse here for clarity and to help with setting up some utility methods.

```
class PageTemplate < ContentfulModel::Base
    belongs_to_many :pages, inverse_of: :template
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

#### An aside on the Contentful UI
There isn't a way to see the parent of a child entity, when you're looking at the child entity. This is something the Contentful gang are thinking about solving, we hear.

## Preview mode
You might want to hit the preview API. Our [contentful_rails](https://github.com/errorstudio/contentful_rails) gem uses it, for example.

Provided you've set a `preview_api_token` in the configuration block, it's dead easy. Just set `ContentfulModel.use_preview_api = true` before making calls.

## Suppressing unvalidated content in preview
There's a slightly weird piece of logic in the Contentful API when you're using preview mode. It returns content which has _failed_ its own validation!

This is something Contentful are planning to address, but for now, we need to filter these out to avoid breaking stuff on the client side. We've added a validator for 'required', using syntax similar to ActiveRecord:

```
class Page
    validates_presence_of :slug, :title, :some_other_vital_field
end
```

If you've defined this in a class, any queries to the API will filter out entities which aren't valid. This applies to both relations (where you might get a collection), or searches.

## Returning nil for fields which aren't defined
If an object is valid, but has content missing from a field, the Contentful API simply doesn't return the field, which is frustrating. That means that you have to check manually for its existence to avoid raising a `ContentfulModel::AttributeNotFoundError`.

We decided it would be nice to be able to declare that certain fields should return nil, rather than raising an error. You can do that as follows:

```
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
