module ContentfulModel
  # Class to wrap query parameters
  class Query
    SYS_PROPERTIES = %w[type id space contentType linkType revision createdAt updatedAt locale]

    attr_accessor :parameters
    def initialize(referenced_class, parameters = nil)
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
      self << { 'limit' => 1 }
      load.first
    end

    def offset(n)
      self << { 'skip' => n }
      self
    end
    alias skip offset

    def limit(n)
      self << { 'limit' => n }
      self
    end

    def locale(locale_code)
      self << { 'locale' => locale_code }
      self
    end

    def paginate(page = 1, per_page = 100, order_field = 'sys.updatedAt', additional_options = {})
      page = 1 if page.nil? || !page.is_a?(Numeric) || page <= 0
      per_page = 100 if per_page.nil? || !per_page.is_a?(Numeric) || per_page <= 0

      skip_records_count = (page - 1) * per_page
      self << { 'limit' => per_page, 'skip' => skip_records_count, 'order' => order_field }
      self << additional_options
      self
    end

    def each_page(per_page = 100, order_field = 'sys.updatedAt', additional_options = {}, &block)
      total = self.class.new(@referenced_class).limit(1).load_children(0).params(additional_options).execute.total

      ((total / per_page) + 1).times do |i|
        page = self.class.new(@referenced_class).paginate(i, per_page, order_field, additional_options).execute
        block[page]
      end
    end

    def each_entry(per_page = 100, order_field = 'sys.updatedAt', additional_options = {}, &block)
      each_page(per_page, order_field, additional_options) do |page|
        page.each do |entry|
          block[entry]
        end
      end
    end

    def load_children(n)
      self << { 'include' => n }
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
      property_type = SYS_PROPERTIES.include?(property_name.to_s) ? 'sys' : 'fields'

      self << { 'order' => "#{prefix}#{property_type}.#{property_name}" }
      self
    end

    def find(id)
      self << { 'sys.id' => id }
      load.first
    end

    def find_by(find_query = {})
      find_query.each do |field, value|
        key = if field.to_s.include?('sys.') || field.to_s.include?('fields.')
                field
              elsif SYS_PROPERTIES.include?(field.to_s)
                "sys.#{field}"
              else
                "fields.#{field}"
              end

        case value
        when Array # we need to do an 'in' query
          self << { "#{key}[in]" => value.join(',') }
        when String, Numeric, true, false
          self << { key.to_s => value }
        when Hash
          # if the search is a hash, use the key to specify the search field operator
          # For example
          # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
          value.each do |search_predicate, search_value|
            self << { "#{key}[#{search_predicate}]" => search_value }
          end
        end
      end

      self
    end
    alias where find_by

    def search(parameters)
      if parameters.is_a?(Hash)
        parameters.each do |field, search|
          # if the search is a hash, use the key to specify the search field operator
          # For example
          # Model.search(start_date: {gte: DateTime.now}) => "fields.start_date[gte]" => DateTime.now
          if search.is_a?(Hash)
            search_key, search_value = *search.flatten
            self << { "fields.#{field.to_s.camelize(:lower)}[#{search_key}]" => search_value }
          else
            self << { "fields.#{field.to_s.camelize(:lower)}[match]" => search }
          end
        end
      elsif parameters.is_a?(String)
        self << { 'query' => parameters }
      end

      self
    end

    def default_parameters
      { 'content_type' => @referenced_class.content_type_id }
    end

    def execute
      query = @parameters.merge(default_parameters)

      discovered_includes = discover_includes
      query['include'] = discovered_includes unless query.key?('include') || discovered_includes == 1

      result = client.entries(query)
      result.items.reject!(&:invalid?)
      result
    end
    alias load execute

    def load!
      load.presence || raise(NotFoundError)
    end

    def client
      @client ||= @referenced_class.client
    end

    def reset
      @parameters = default_parameters
    end

    def discover_includes
      @referenced_class.discovered_include_level
    end
  end
end
