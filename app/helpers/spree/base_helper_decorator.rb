module Spree
  BaseHelper.class_eval do
    # Helper method for interpreting facets from Elasticsearch. Something like a before filter.
    # Sorting, changings things, the world is your oyster
    # Input is a hash
    def process_facets(facets)
      facets
    end
  end
end
