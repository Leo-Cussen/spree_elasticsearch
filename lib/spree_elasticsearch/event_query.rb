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
        [ {'specialisation.start_time' => { ignore_unmapped: true, order: 'asc' }} ]
      end

      private

      def date_filter
        filter = { from: 'now'}

        if date_from = format_date(starting['from'], starting['time_zone'])
          filter[:from] = "#{date_from.beginning_of_day.iso8601}"
        end

        if date_upto = format_date(starting['upto'], starting['time_zone'])
          filter[:to] = "#{date_upto.end_of_day.iso8601}"
        end

        { range: { 'specialisation.start_time' => filter } }
      end

      def format_date(value, time_zone)
        return unless value

        Date.parse(value).in_time_zone(time_zone)
      rescue ArgumentError
        nil
      end
    end
  end
end
