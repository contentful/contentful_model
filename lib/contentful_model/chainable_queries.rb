module ContentfulModel
  module ChainableQueries
    def self.included(base)
      base.include ContentfulModel::Queries
      base.extend ClassMethods
    end

    module ClassMethods

      def all
        raise ArgumentError, "You need to set self.content_type in your model class" if @content_type_id.nil?
        self
      end

      def first
        @query << {'limit' => 1}
        load.first
      end

      def offset(n)
        @query << {'skip' => n}
        self
      end

      def order(args)
        prefix = ''
        if args.is_a?(Hash)
          column = args.first.first.to_s
          prefix = '-' if args.first.last == :desc
        elsif args.is_a?(Symbol)
          column = args.to_s
          prefix = ''
        end
        @query << {'order' => "#{prefix}fields.#{column.camelize(:lower)}"}
        puts @query.inspect
        self
      end

      alias_method :skip, :offset

      def find_by(*args)
        args.each do |query|
          #query is a hash
          if query.values.first.is_a?(Array) #we need to do an 'in' query
            @query << {"fields.#{query.keys.first}[in]" => query.values.first.join(",")}
          elsif query.values.first.is_a?(String)
            @query << {"fields.#{query.keys.first}" => query.values.first}
          end
        end
        self
      end

      def search(parameters)
        if parameters.is_a?(Hash)
          parameters.each do |field, search|
            @query << {"fields.#{field}[match]" => search}
          end
        elsif parameters.is_a?(String)
          @query << {"query" => parameters}
        end
        self
      end

    end

  end
end