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
   self.content_type = "content type id for this model"
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
Accepts a hash of options to include in the search, as similar as possible to ActiveRecord version.

```
Foo.find_by(someField: [searchquery1, searchquery2], someOtherField: "bar")
```

You'll see from the example above that it accepts an array of search terms which will invoke an 'in' query.

# To Do
There are quite a few outstanding tasks:

* Some tests :-)
* Expose the query object to allow an arbitrary query against the Contentful API
* Hook in the Contentful Management API gem to allow saves: https://github.com/contentful/contentful-management.rb