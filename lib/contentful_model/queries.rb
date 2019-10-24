require_relative 'query'

module ContentfulModel
  # Module to extend Base with querying capabilities
  module Queries
    def self.included(base)
      base.extend ClassMethods
    end

    # Class methods for Queries
    module ClassMethods
      def query
        ContentfulModel::Query.new(self)
      end

      def all
        fail ArgumentError, 'You need to set self.content_type in your model class' if @content_type_id.nil?
        query
      end

      def load
        all.load
      end

      def load!
        all.load!
      end

      def first
        query.first
      end

      def params(options)
        query.params(options)
      end

      def offset(n)
        query.offset(n)
      end
      alias skip offset

      def limit(n)
        query.limit(n)
      end

      def locale(locale_code)
        query.locale(locale_code)
      end

      def paginate(page = 1, per_page = 100, order_field = 'sys.updatedAt', additional_options = {})
        query.paginate(page, per_page, order_field, additional_options)
      end

      def each_page(per_page = 100, order_field = 'sys.updatedAt', additional_options = {}, &block)
        query.each_page(per_page, order_field, additional_options, &block)
      end

      def each_entry(per_page = 100, order_field = 'sys.updatedAt', additional_options = {}, &block)
        query.each_entry(per_page, order_field, additional_options, &block)
      end

      def load_children(n)
        query.load_children(n)
      end

      def order(args)
        query.order(args)
      end

      def find(id)
        query.find(id)
      end

      def find_by(find_query = {})
        query.find_by(find_query)
      end

      def search(parameters)
        query.search(parameters)
      end
    end
  end
end
