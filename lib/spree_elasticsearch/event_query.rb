module Spree
  module Elasticsearch
    # Class used to query elasticsearch for event products. The idea is that the query is dynamically build based on the parameters.
    class EventQuery < ProductQuery

      attribute :starting, {}

      def add_and_filters
        super

        @and_filter << date_filter
      end

      def sort
      private

      def date_filter
        filter = { gte: 'now'}

        if date_from = format_date(starting['from'])
          filter[:gte] = "#{date_from}"
        end

        if date_upto = format_date(starting['upto'])
          filter[:lte] = "#{date_upto}"
        end

        { range: { 'specialisation.start_time' => filter } }
      end

      def format_date(value)
        return unless value

        Date.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
