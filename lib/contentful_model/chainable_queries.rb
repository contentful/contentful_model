module ContentfulModel
  module ChainableQueries
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        attr_accessor :query
      end
    end

    module ClassMethods
      def all
        raise ArgumentError, "You need to set self.content_type in your model class" if @content_type_id.nil?
        @query ||= ContentfulModel::Query.new(self)
        self
      end

      def first
        @query ||= ContentfulModel::Query.new(self)
        @query << {'limit' => 1}
        @query.execute.first
      end

      def offset(n)
        @query ||= ContentfulModel::Query.new(self)
        @query << {'skip' => n}
        self
      end

      alias_method :skip, :offset

      def find_by(*args)
        @query ||= ContentfulModel::Query.new(self)
        args.each do |query|
          @query << {"fields.#{query.keys.first}" => query.values.first}
        end
        self
      end

      def search(parameters)
        @query ||= ContentfulModel::Query.new(self)
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
    end

  end
end