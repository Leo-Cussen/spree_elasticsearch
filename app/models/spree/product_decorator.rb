module Spree
  Product.class_eval do
    include ::Elasticsearch::Model
    after_commit lambda { __elasticsearch__.index_document  },  on: :create
    after_commit lambda { __elasticsearch__.index_document  },  on: :update
    after_commit lambda { __elasticsearch__.delete_document },  on: :destroy

    index_name Spree::Elasticsearch::Config.index
    document_type 'spree_product'

    mapping _all: {"index_analyzer" => "nGram_analyzer", "search_analyzer" => "standard"} do
      indexes :name, type: 'multi_field' do
        indexes :name, type: 'string', analyzer: 'nGram_analyzer', boost: 1.5
        indexes :untouched, type: 'string', include_in_all: false, index: 'not_analyzed'
      end
      indexes :description, analyzer: 'snowball'
      indexes :available_on, type: 'date', format: 'dateOptionalTime', include_in_all: false
      indexes :available_until, type: 'date', format: 'dateOptionalTime', include_in_all: false
      indexes :price, type: 'double'
      indexes :sku, type: 'string', index: 'not_analyzed'
      indexes :taxon_ids, type: 'string', index: 'not_analyzed'
    end

    def as_indexed_json(options={})
      result = as_json({
        methods: [:price, :sku],
        only: [:available_on, :description, :name, :available_until],
        include: {
          variants: {
            only: [:sku],
            include: {
              option_values: {
                only: [:name, :presentation]
              }
            }
          }
        }
      })
      result[:taxon_ids] = taxons.map(&:self_and_ancestors).flatten.uniq.map(&:id) unless taxons.empty?
      result
    end

  end
end
