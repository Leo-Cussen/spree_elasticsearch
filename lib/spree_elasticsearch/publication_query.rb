module Spree
  module Elasticsearch
    # Class used to query elasticsearch for publications products.
    class PublicationQuery < ProductQuery

      def add_and_filters
        super
        @and_filter << { missing: { field: 'specialisation' } }
      end
    end
  end
end
