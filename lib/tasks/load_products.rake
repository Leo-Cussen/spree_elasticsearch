namespace :spree_elasticsearch do
  desc "Load all products into the index."
  task :load_products => :environment do
    unless Elasticsearch::Model.client.indices.exists index: Spree::Elasticsearch::Config.index
      Elasticsearch::Model.client.indices.create \
        index: Spree::Elasticsearch::Config.index,
        body: {
          settings: Spree::Product.settings.to_hash,
          mappings: Spree::Product.mappings.to_hash
        }
    end
    Spree::Product.__elasticsearch__.import
  end
end
