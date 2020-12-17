module Spree
  module Elasticsearch
    # Class used to query elasticsearch for products. The idea is that the query is dynamically build based on the parameters.
    class ProductQuery
      include ::Virtus.model

      attribute :from, Integer, default: 0
      attribute :query, String
      attribute :taxons, Array
      attribute :sorting, String

      # Method that creates the actual query based on the current attributes.
      # The idea is to always to use the following schema and fill in the blanks.
      # {
      #   query: {
      #     filtered: {
      #       query: {
      #         query_string: { query: , fields: [] }
      #       }
      #       filter: {
      #         and: [
      #           { terms: { taxons: [] } },
      #         ]
      #       }
      #     }
      #   }
      #   sort: [],
      #   from: ,
      #   facets:
      # }
      def to_hash
        # basic skeleton
        @result = {
          query: {
            filtered: {
              query: build_query
            }
          },
          sort: sort,
          from: from,
          aggregations: facets
        }

        add_filtering

        @result
      end

      private

      def add_filtering
        @and_filter = []
        add_and_filters
        @result[:query][:filtered][:filter] = { and: @and_filter } unless @and_filter.empty?
      end

      def add_and_filters
        # taxon filters have an effect on the facets
        @and_filter << taxons_filter unless valid_taxons.empty?
        # only return products that are available
        @and_filter << { range: { available_on: { lte: 'now' } } }
        @and_filter << { or: [
          { range: { available_until: {gte: 'now'} } },
          { missing: { field: 'available_until'} }
        ]}
      end

      def build_query
        if query.blank? # nil or empty
          { match_all: {} }
        else
          {
            query_string: {
              query: escaped_query,
              fields: ['name', 'name.fuzzy', 'description', 'description.fuzzy', 'sku'],
              use_dis_max: true
            }
          }
        end
      end

      def facets
        {
          taxon_ids: { terms: { field: 'taxon_ids', size: 1000000 } }
        }
      end

      def sort
        case @sorting
        when 'name_asc'
          [ {'name.untouched' => { ignore_unmapped: true, order: 'asc' }}, '_score' ]
        when 'name_desc'
          [ {'name.untouched' => { ignore_unmapped: true, order: 'desc' }}, '_score' ]
        else
          [ '_score', {'name.untouched' => { ignore_unmapped: true, order: 'asc' }} ]
        end
      end

      def taxons_filter
        {
          terms:
          {
            taxon_ids: valid_taxons,
            execution: 'and'
          }
        }
      end

      def valid_taxons
        @valid_taxons ||= taxons.reject(&:blank?)
      end

      def escaped_query
        @escaped_query ||= query.gsub(/\//, '\/')
      end
    end

  end
end
