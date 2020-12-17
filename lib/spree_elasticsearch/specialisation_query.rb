module Spree
  module Elasticsearch
    # Class used to query elasticsearch for products by specialisation.
    class SpecialisationQuery < ProductQuery

      attribute :specialisation_types, []

      def add_and_filters
        super

        if specialisation_types.any?
          @and_filter << { terms: { specialisation_type: specialisation_types } }
        end
      end
    end
  end
end
