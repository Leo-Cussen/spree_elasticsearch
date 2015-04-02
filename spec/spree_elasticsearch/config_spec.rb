require 'spec_helper'

RSpec.describe Spree::Elasticsearch::Config do
  subject { Spree::Elasticsearch::Config }
  describe "index" do
    let(:index) { subject.index }
    let(:environment_value) { nil }

    before do
      allow(ENV).to receive(:[]).with('PRODUCT_INDEX').and_return environment_value
      allow(Rails).to receive(:env).and_return 'test'
    end

    context "when PRODUCT_INDEX environment variable is set" do
      let(:environment_value) { 'woot' }
      it "is taken from the environment variable" do
        expect(index).to eql 'woot'
      end
    end

    context "when PRODUCT_INDEX environment variable is not set" do
      let(:environment_value) { nil }
      it "is taken from the Rails environment" do
        expect(index).to eql 'test'
      end
    end
  end
end
