module Spree
  module Search
    # The following search options are available.
    #   * taxon
    #   * keywords in name or description
    class EventElasticsearch < Spree::Search::Elasticsearch

      attribute :starting, {}

      protected

      def product_query
        product_query_class = super
        product_query_class.starting = self.starting
        product_query_class
      end

      def prepare(params)
        super

        @starting = params[:starting] || {}
      end

      def product_query_class
        Spree::Elasticsearch::EventQuery
      end
    end
  end
end
