module Spree
  module Elasticsearch
    # Class used to query elasticsearch for event products. The idea is that the query is dynamically build based on the parameters.
    class EventQuery < ProductQuery

      def add_and_filters
        super
        @and_filter << { range: { 'specialisation.start_time' => { gte: 'now' } } }
      end

      def sort
          [ {'specialisation.start_time' => { ignore_unmapped: true, order: 'asc' }} ]
      end
    end
  end
end
