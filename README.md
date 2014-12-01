# ContentfulModel

This is a thin wrapper around the [Contentful.rb](https://github.com/contentful/contentful.rb) api client library.

It allows you to inherit from `ContentfulModel::Base` and specify the content type id, and optionally, fields to coerce in a specific way.

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
   self.content_type = content type id for this model"

   coerce_field birthday: :date
   coerce_field store_id: :integer
end
```
