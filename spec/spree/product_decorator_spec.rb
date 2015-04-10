require 'spec_helper'

RSpec.describe Spree::Product do
  def with_transaction
    ::ActiveRecord::Base.connection.commit_transaction if ::ActiveRecord::Base.connection.transaction_open?
    ::ActiveRecord::Base.connection.begin_transaction
    result = yield
    ::ActiveRecord::Base.connection.commit_transaction
    result
  end

  describe "indexed JSON" do
    let(:indexed_json) { JSON.load JSON.dump subject.as_indexed_json }

    let(:subject) do
      FactoryGirl.build(
        :product,
        description: '<div class="awesome">Hello!</div><b>Goodbye.</b>',
        name: 'The product',
        sku: 'the-sku',
        available_on: DateTime.parse('2010-10-10'),
        price: 22.50
      )
    end

    {
      name: 'The product',
      sku: 'the-sku',
      available_on: "2010-10-10 00:00:00 UTC",
      price: '22.5'
    }.each do |attribute, value|
      it "includes #{attribute}" do
        expect(indexed_json[attribute.to_s]).to eq value
      end
    end

    it "includes description without HTML tags" do
      expect(indexed_json["description"]).to eq 'Hello!Goodbye.'
    end
  end

  describe "indexing" do
    subject do
      with_transaction do
        FactoryGirl.build(:product).tap do |product|
          product.instance_variable_set(:@__elasticsearch__, elasticsearch)
          product.save
        end
      end
    end

    let(:elasticsearch) { double('elasticsearch', delete_document: true, index_document: true, client: nil) }

    before do
      allow(subject).to receive(:__elasticsearch__).and_return elasticsearch
    end

    context "when created" do
      it "is indexed" do
        expect(elasticsearch).to have_received(:index_document)
      end
    end

    describe "when updated and committed" do
      context "if set to 'destroyed'" do
        it "deletes the document from the index" do
          with_transaction do
            expect(elasticsearch).to receive(:delete_document)
            subject.update!(deleted_at: DateTime.now)
          end
        end
      end

      context "if not set to 'destroyed'" do
        it "is completely re-indexed" do
          with_transaction do
            expect(elasticsearch).to receive(:index_document)
            subject.update!(name: "Stuff")
          end
        end
      end
    end
  end
end
