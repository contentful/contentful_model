module ContentfulModel
  class Query
    attr_accessor :parameters
    def initialize(referenced_class, parameters=nil)
      @parameters = parameters || {}
      @referenced_class = referenced_class
    end

    def <<(parameters)
      @parameters.merge!(parameters)
    end

    def params(options)
      self << options
      self
    end

    def first
      self << {'limit' => 1}
      self.load.first
    end

    def offset(n)
      self << {'skip' => n}
      self
    end
    alias_method :skip, :offset

    def limit(n)
      self << {'limit' => n}
      self
    end

    def locale(locale_code)
      self << {'locale' => locale_code}
      self
    end

    def paginate(page = 1, per_page = 100, order_field = 'sys.updatedAt')
      page = 1 if page.nil? || !page.is_a?(Numeric) || page <= 0
      per_page = 100 if per_page.nil? || !per_page.is_a?(Numeric) || per_page <= 0

      skip_records_count = (page - 1) * per_page
      self << { 'limit' => per_page, 'skip' => skip_records_count, 'order' => order_field }
      self
    end

    def load_children(n)
      self << {'include' => n}
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

      self << {'order' => "#{prefix}#{property_type}.#{property_name}"}
      self
    end

    def find(id)
      self << {'sys.id' => id}
      self.load.first
    end

    def find_by(find_query = {})
      find_query.each do |field, value|
        key = if field.to_s.include?('sys.') || field.to_s.include?('fields.')
                field
              else
                "fields.#{field}"
              end

        case value
        when Array  #we need to do an 'in' query
          self << {"#{key}[in]" => value.join(",")}
        when String, Numeric, true, false
          self << {"#{key}" => value}
        when Hash
          # if the search is a hash, use the key to specify the search field operator
          # For example
          # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
          value.each do |search_predicate, search_value|
            self << {"#{key}[#{search_predicate}]" => search_value}
          end
        end
      end

      self
    end
    alias_method :where, :find_by

    def search(parameters)
      if parameters.is_a?(Hash)
        parameters.each do |field, search|
          # if the search is a hash, use the key to specify the search field operator
          # For example
          # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
          if search.is_a?(Hash)
            search_key, search_value = *search.flatten
            self << {"fields.#{field.to_s.camelize(:lower)}[#{search_key}]" => search_value}
          else
            self << {"fields.#{field.to_s.camelize(:lower)}[match]" => search}
          end
        end
      elsif parameters.is_a?(String)
        self << {"query" => parameters}
      end

      self
    end

    def default_parameters
      { 'content_type' => @referenced_class.content_type_id }
    end

    def execute
      query = @parameters.merge(default_parameters)
      result = client.entries(query)
      result.items.reject! { |e| e.invalid? }
      result
    end
    alias_method :load, :execute

    def client
      @client ||= @referenced_class.client
    end

    def reset
      @parameters = default_parameters
    end
  end
end
