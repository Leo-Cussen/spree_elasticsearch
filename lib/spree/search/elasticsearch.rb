module Spree
  module Search
    # The following search options are available.
    #   * taxon
    #   * keywords in name or description
    class Elasticsearch <  Spree::Core::Search::Base
      include ::Virtus.model

      attribute :query, String
      attribute :taxons, Array
      attribute :browse_mode, Boolean, default: true
      attribute :per_page, String
      attribute :page, String
      attribute :sorting, String

      def initialize(params)
        self.current_currency = Spree::Config[:currency]
        prepare(params)
      end

      def retrieve_products
        Spree::Product.__elasticsearch__.search(
          product_query.to_hash
        ).limit(per_page).page(page).records
      end

      def explain(id)
        explain_query(id, {query: product_query.to_hash[:query]})
      end

      def explain_query(id, query_hash)
        ::Elasticsearch::Model.client.explain(
          id: id,
          body: query_hash,
          index: Spree::Product.index_name,
          type: Spree::Product.document_type
        )
      end

      protected

      def from
        (page - 1) * per_page
      end

      def product_query
        product_query_class.new(
          query: query,
          taxons: taxons,
          browse_mode: browse_mode,
          from: from,
          sorting: sorting
        )
      end

      def product_query_class
        Spree::Elasticsearch::ProductQuery
      end

      # converts params to instance variables
      def prepare(params)
        @query = params[:keywords]
        @sorting = params[:sorting]
        @taxons = params[:taxon] unless params[:taxon].nil?
        @browse_mode = params[:browse_mode] unless params[:browse_mode].nil?

        @per_page = (params[:per_page].to_i <= 0) ? Spree::Config[:products_per_page] : params[:per_page].to_i
        @page = (params[:page].to_i <= 0) ? 1 : params[:page].to_i
      end
    end
  end
end
