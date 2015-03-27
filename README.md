# ContentfulModel

This is a thin wrapper around the [Contentful.rb](https://github.com/contentful/contentful.rb) api client library.

It allows you to inherit from `ContentfulModel::Base` and specify the content type id, and optionally, fields to coerce in a specific way.

Note that this library doesn't allow you to save changes to your models back to Contentful. We need to use the Contentful Management API for that. Pull requests welcome!

# Usage

## Configure ContentfulModel

Configure ContentfulModel with a block. In a Rails app this is best done in an initializer:

```
ContentfulModel.configure do |config|
  config.access_token = "your access token in here"
  config.space = "your space id in here"
  config.options = {
    #extra options to send to the Contentful::Client
  }
end

```

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
   self.content_type = "content type id for this model"

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

### `find([id]`
Returns the entry of the content type you've called, matching the id you passed into the `find()` method. _Does not_ require `load()`.

```
Foo.find("someidfromcontentful")
```

### `find_by([hash])`
Accepts a hash of options to include in the search, as similar as possible to ActiveRecord version. __Note__ that this doesn't work (and will throw an error) on fields which need the full-text search. This needs fixing.

```
Foo.find_by(someField: [searchquery1, searchquery2], someOtherField: "bar")
```

You'll see from the example above that it accepts an array of search terms which will invoke an 'in' query.

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
    belongs_to_many :pages, inverse_of :template
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

From this, you can:

* Build up a tree from calls to the top-level entity (e.g. a navigation tree)
* Reverse-iterate up the tree from a given page (e.g. breadcrumbs)

#### An aside on the Contentful UI
There isn't a way to see the parent of a child entity, when you're looking at the child entity. This is something the Contentful gang are thinking about solving, we hear.


# To Do
There are quite a few outstanding tasks:

* Some tests :-)
* Expose the query object to allow an arbitrary query against the Contentful API
* Hook in the Contentful Management API gem to allow saves: https://github.com/contentful/contentful-management.rb

# Licence
MIT - please see MIT-LICENCE in this repo.

# Contributing
Please feel free to contribute. We would love your input.

* Fork the repo
* Make changes
* Commit and make a PR :-)
