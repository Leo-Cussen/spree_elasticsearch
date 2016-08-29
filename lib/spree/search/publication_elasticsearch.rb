module Spree
  module Search
    # The following search options are available.
    #   * taxon
    #   * keywords in name or description
    class PublicationElasticsearch < Spree::Search::Elasticsearch

      protected

      def product_query_class
        Spree::Elasticsearch::PublicationQuery
      end
    end
  end
end
