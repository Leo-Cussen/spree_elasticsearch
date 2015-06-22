require 'spec_helper'

RSpec.describe Spree::Search::EventElasticsearch do

  context "when initialized with parameters" do
    let(:params) do
      {
        :keywords => 'query',
        :browse_mode => false,
        :sorting => "sort_by",
        :taxon => [1,2,3],
        :per_page => "10", :page => "2",
      }
    end

    subject { Spree::Search::EventElasticsearch.new(params) }

    context "retrieving products" do
      it "initializes a configured ProductQuery" do
        expect(Spree::Elasticsearch::EventQuery).to receive(:new).with(
          {
          :query => 'query', :taxons => [1,2,3], :browse_mode => false,
          :from => 10, :sorting => "sort_by"
          }
        ).and_return instance_double('Spree::Elasticsearch::EventQuery', to_hash: {})
        subject.retrieve_products
      end

    end
  end
end
