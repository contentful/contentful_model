module ContentfulModel
  module ChainableQueries
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        cattr_accessor :query
      end
    end

    module ClassMethods
      def get_query
        @query ||= ContentfulModel::Query.new(self)
      end

      def all
        get_query
        raise ArgumentError, "You need to set self.content_type in your model class" if @content_type_id.nil?
        self
      end

      def first
        get_query
        @query << {'limit' => 1}
        @query.execute.first
      end

      def offset(n)
        get_query
        puts @query.inspect
        @query << {'skip' => n}
        self
      end

      alias_method :skip, :offset

      def find_by(*args)
        get_query
        args.each do |query|
          #query is a hash
          if query.values.first.is_a?(Array) #we need to do an 'in' query
            @query << {"fields.#{query.keys.first}[in]" => query.values.first.join(",")}
          else
            @query << {"fields.#{query.keys.first}" => query.values.first}
          end
        end
        self
      end

      def search(parameters)
        get_query
        if parameters.is_a?(Hash)
          parameters.each do |field, search|
            @query << {"fields.#{field}[match]" => search}
          end
        elsif parameters.is_a?(String)
          @query << {"query" => parameters}
        end
        self
      end

      def load
        @query.execute
      end

      def find(id)
        get_query
        @query << {'sys.id' => id}
        @query.execute.first
      end

    end

  end
end