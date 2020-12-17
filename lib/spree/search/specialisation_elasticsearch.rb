module Spree
  module Search
    # The following search options are available.
    #   * taxon
    #   * keywords in name or description
    class SpecialisationElasticsearch < Spree::Search::Elasticsearch

      attribute :specialisation_types, []

      protected

      def prepare(params)
        super

        @specialisation_types = params[:specialisation_types] || []
      end

      def product_query
        product_query_class = super
        product_query_class.specialisation_types = self.specialisation_types
        product_query_class
      end

      def product_query_class
        Spree::Elasticsearch::SpecialisationQuery
      end
    end
  end
end
