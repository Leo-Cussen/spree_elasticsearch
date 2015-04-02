module Spree
  module Elasticsearch
    class Config
      class << self
        def index
          ENV['PRODUCT_INDEX'] || Rails.env
        end
      end
    end
  end
end
