require 'spec_helper'

RSpec.describe Spree::Search::Elasticsearch do

  context "when initialized with parameters" do
    let(:params) do
      {
        :keywords => 'query',
        :browse_mode => false,
        :sorting => "sort_by",
        :taxon => [1,2,3],
        :per_page => "10", :page => "2",
        search: {
          properties: {one: 1},
          price: {
            min: "100",
            max: "120",
          }
        }
      }
    end

    expected_settings = {
      :query => 'query', :price_min => 100.0, :price_max => 120.0,
      :taxons => [1,2,3], :browse_mode => false, :properties => {one:1},
      :per_page => 10, :page => 2, :sorting => "sort_by"
    }

    subject { Spree::Search::Elasticsearch.new(params) }

    context "converting the parameters to settings" do
      expected_settings.each do |name, value|
        it "sets #{name} correctly" do
          expect(subject.send(name)).to eql value
        end
      end
    end

    context "retrieving products" do
      let(:query_hash) { double('query hash') }
      let(:result) { double('search_result', records: 'products found') }
      let(:elasticsearch_proxy) { double('__elasticsearch__', search: result) }
      let(:product_query) do
        instance_double('Spree::Elasticsearch::ProductQuery', to_hash: query_hash)
      end
      let(:products_found) { subject.retrieve_products }

      before do
        allow(Spree::Elasticsearch::ProductQuery).to receive(:new).and_return product_query
        allow(Spree::Product).to receive(:__elasticsearch__).and_return elasticsearch_proxy
        allow(result).to receive(:limit).and_return result
        allow(result).to receive(:page).and_return result
        products_found
      end

      it "initializes a configured ProductQuery" do
        expect(Spree::Elasticsearch::ProductQuery).to have_received(:new).with (
          {
          :query => 'query', :price_min => 100.0, :price_max => 120.0,
          :taxons => [1,2,3], :browse_mode => false, :properties => {one:1},
          :from => 10, :sorting => "sort_by"
          }
        )
      end

      it "searches using the product query as a hash" do
        expect(elasticsearch_proxy).to have_received(:search).with query_hash
      end

      it "paginates the results" do
        expect(result).to have_received(:limit).with 10
        expect(result).to have_received(:page).with 2
      end
      it "returns the records" do
        expect(products_found).to eql 'products found'
      end
    end
  end
end
