require_relative 'queries'

module ContentfulModel
  module ChainableQueries
    def self.included(base)
      base.include ContentfulModel::Queries
      base.extend ClassMethods
    end

    module ClassMethods
      def all
        raise ArgumentError, 'You need to set self.content_type in your model class' if @content_type_id.nil?
        self
      end

      def params(options)
        @query << options
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

      def limit(n)
        @query << {'limit' => n}
        self
      end

      def locale(locale_code)
        @query << {'locale' => locale_code}
        self
      end

      def paginate(page = 1, per_page = 100)
        page = 1 if page.nil?
        per_page = 25 if per_page.nil?
        skip_records_count = (page - 1) * per_page
        @query << { 'limit' => per_page, 'skip' => skip_records_count }
        self
      end

      def load_children(n)
        @query << {'include' => n}
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
        else
          column = args.to_s
        end
        property_name = column.camelize(:lower).to_sym
        sys_properties = ['type', 'id', 'space', 'contentType', 'linkType', 'revision', 'createdAt', 'updatedAt', 'locale']
        property_type = sys_properties.include?(property_name.to_s) ? 'sys' : 'fields'

        @query << {'order' => "#{prefix}#{property_type}.#{property_name}"}
        self
      end

      alias_method :skip, :offset

      def find_by(query = {})
        query.each do |field, value|
          key = if field.to_s.include?('sys.') || field.to_s.include?('fields.')
                  field
                else
                  "fields.#{field}"
                end

          case value
          when Array  #we need to do an 'in' query
            @query << {"#{key}[in]" => value.join(",")}
          when String, Numeric, true, false
            @query << {"#{key}" => value}
          when Hash
            # if the search is a hash, use the key to specify the search field operator
            # For example
            # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
            value.each do |search_predicate, search_value|
              @query << {"#{key}[#{search_predicate}]" => search_value}
            end
          end
        end

        self
      end

      def search(parameters)
        if parameters.is_a?(Hash)
          parameters.each do |field, search|
            # if the search is a hash, use the key to specify the search field operator
            # For example
            # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
            if search.is_a?(Hash)
              search_key, search_value = *search.flatten
              @query << {"fields.#{field.to_s.camelize(:lower)}[#{search_key}]" => search_value}
            else
              @query << {"fields.#{field.to_s.camelize(:lower)}[match]" => search}
            end
          end
        elsif parameters.is_a?(String)
          @query << {"query" => parameters}
        end
        self
      end
    end
  end
end
