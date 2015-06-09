module Spree
  module Elasticsearch
    # Class used to query elasticsearch for products. The idea is that the query is dynamically build based on the parameters.
    class ProductQuery
      include ::Virtus.model

      attribute :from, Integer, default: 0
      attribute :price_min, Float
      attribute :price_max, Float
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
      #   filter: { range: { price: { lte: , gte: } } },
      #   sort: [],
      #   from: ,
      #   facets:
      # }
      def to_hash
        q = { match_all: {} }
        unless query.blank? # nil or empty
          q = {
            query_string: {
              query: escaped_query,
              fields: ['name','name.fuzzy', 'description', 'description.fuzzy', 'sku'],
              use_dis_max: true
            }
          }
        end
        query = q

        and_filter = []

        sorting = case @sorting
                  when 'name_asc'
                    [ {'name.untouched' => { ignore_unmapped: true, order: 'asc' }}, {'price' => { ignore_unmapped: true, order: 'asc' }}, '_score' ]
                  when 'name_desc'
                    [ {'name.untouched' => { ignore_unmapped: true, order: 'desc' }}, {'price' => { ignore_unmapped: true, order: 'asc' }}, '_score' ]
                  when 'price_asc'
                    [ {'price' => { ignore_unmapped: true, order: 'asc' }}, {'name.untouched' => { ignore_unmapped: true, order: 'asc' }}, '_score' ]
                  when 'price_desc'
                    [ {'price' => { ignore_unmapped: true, order: 'desc' }}, {'name.untouched' => { ignore_unmapped: true, order: 'asc' }}, '_score' ]
                  when 'score'
                    [ '_score', {'name.untouched' => { ignore_unmapped: true, order: 'asc' }}, {'price' => { ignore_unmapped: true, order: 'asc' }} ]
                  else
                    [ '_score', {'name.untouched' => { ignore_unmapped: true, order: 'asc' }}, {'price' => { ignore_unmapped: true, order: 'asc' }} ]
                  end

        # facets
        facets = {
          price: { statistical: { field: 'price' } },
          taxon_ids: { terms: { field: 'taxon_ids', size: 1000000 } }
        }

        # basic skeleton
        result = {
          query: { filtered: {} },
          sort: sorting,
          from: from,
          facets: facets
        }

        # add query and filters to filtered
        result[:query][:filtered][:query] = query
        # taxon filters have an effect on the facets
        and_filter << taxons_filter unless valid_taxons.empty?
        # only return products that are available
        and_filter << { range: { available_on: { lte: 'now' } } }
        and_filter << { or: [
          { range: { available_until: {gte: 'now'} } },
          { missing: { field: 'available_until'} }
        ]}
        result[:query][:filtered][:filter] = { and: and_filter } unless and_filter.empty?

        # add price filter outside the query because it should have no effect on facets
        if price_min && price_max && (price_min < price_max)
          result[:filter] = { range: { price: { gte: price_min, lte: price_max } } }
        end

        result
      end

      private

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
