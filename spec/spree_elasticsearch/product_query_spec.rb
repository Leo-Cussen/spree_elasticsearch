require 'spec_helper'

RSpec.describe Spree::Elasticsearch::ProductQuery do
  context 'when initialized' do
    let(:search_terms) { 'search terms' }
    let(:from) { 0 }
    let(:price_min) { 100 }
    let(:price_max) { 120 }
    let(:sorting) { 'score' }

    let(:args) do
      {
        query: search_terms,
        from: from,
        price_min: price_min,
        price_max: price_max,
        sorting: sorting,
      }
    end

    subject { Spree::Elasticsearch::ProductQuery.new(args) }

    let(:hash) { subject.to_hash }

    describe 'the hash created' do
      describe 'filtered query' do
        let(:query) { hash[:query][:filtered] }

        it 'specifies a query string on name, description and sku, including fuzzy indexes' do
          expect(query[:query][:query_string]).to eql({
            query: 'search terms',
            fields: ['name', 'name.fuzzy', 'description', 'description.fuzzy', 'sku'],
            use_dis_max: true
          })
        end

        describe 'filter' do
          let(:filter) { query[:filter] }
          it 'is on availability range' do
            expect(filter).to eql({
              and: [
                { range: { available_on: {lte: 'now'} } },
                { or:
                  [
                    { range: { available_until: {gte: 'now'} } },
                    { missing: { field: 'available_until'} }
                  ]
                }
              ]
            })
          end
        end
      end

      it 'specifies a sort' do
        expect(hash[:sort]).to eql([
          '_score',
          { 'name.untouched'=>{ ignore_unmapped: true, order: 'asc' } },
          { 'price'=>{ ignore_unmapped: true, order: 'asc' } }
        ])
      end

      it 'specifies a starting point' do
        expect(hash[:from]).to eql 0
      end

      context 'facets' do
        let(:facets) { hash[:facets] }
        it 'include price' do
          expect(facets[:price]).to eql({
            statistical: { field: 'price' }
          })
        end
        it 'include taxons' do
          expect(facets[:taxon_ids]).to eql({
            terms: { field: 'taxon_ids', size: 1000000 }
          })
        end
      end

      describe 'when taxons are specified' do
        let(:taxons) { [1,2,3] }
        before do
          args[:taxons] = taxons
        end

        describe 'filter' do
          let(:filter) { hash[:query][:filtered][:filter] }

          it 'includes taxons' do
            expect(filter[:and]).to include({
              terms: { taxon_ids: taxons }
            })
          end

          context 'when empty taxons are specified' do
            let(:taxons) { [nil, 0, 1, 2, ''] }
            it 'removes them from the filter' do
              expect(filter[:and]).to include({
                terms: { taxon_ids: [0, 1, 2]}
              })
            end
          end
        end
      end
    end
  end
end
