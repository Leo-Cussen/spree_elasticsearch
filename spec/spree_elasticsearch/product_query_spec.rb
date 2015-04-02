require 'spec_helper'

RSpec.describe Spree::Elasticsearch::ProductQuery do
  context "when initialized" do
    let(:query) { 'search terms' }
    let(:from) { 0 }
    let(:price_min) { 100 }
    let(:price_max) { 120 }
    let(:properties) do
      {one: 1}
    end
    let(:taxons) { [1,2,3] }
    let(:sorting) { 'score' }

    subject do
      Spree::Elasticsearch::ProductQuery.new(
        query: query
      )
    end

    let(:hash) { subject.to_hash }

    it "creates a proper query hash" do
      expect(hash).to eql({
        min_score: 0.1,
        query: {
          filtered:{
            query: {
              query_string: {
                query: "search terms",
                fields: ["name^5", "description", "sku"],
                default_operator: "AND",
                use_dis_max: true
              }
            },
            filter: {
              and: [
                {range: { available_on: {lte: "now"} } }
              ]
            }
          }
        },
        sort: [
          "_score",
          {
            "name.untouched"=>{
              ignore_unmapped: true, order: "asc"
            }
          },
          {
            "price"=>{
              ignore_unmapped: true, order: "asc"
            }
          }
        ],
        from: 0,
        facets: {
          price: { statistical: { field: "price" } },
          properties: {
            terms: { field: "properties", order: "count", size: 1000000 }
          },
          taxon_ids: {
            terms: { field: "taxon_ids", size: 1000000 }
          }
        }
      })
    end
  end
end

