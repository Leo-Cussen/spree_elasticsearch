module Spree
  module Search
    # The following search options are available.
    #   * taxon
    #   * keywords in name or description
    class EventElasticsearch < Spree::Search::Elasticsearch

      protected

      def product_query_class
        Spree::Elasticsearch::EventQuery
      end
    end
  end
end
