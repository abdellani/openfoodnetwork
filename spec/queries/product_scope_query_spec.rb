# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductScopeQuery do
  let!(:taxon) { create(:taxon) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:supplier2) { create(:supplier_enterprise) }
  let!(:product) { create(:product, supplier:, primary_taxon: taxon) }
  let!(:product2) { create(:product, supplier: supplier2, primary_taxon: taxon) }
  let!(:current_api_user) { supplier_enterprise_user(supplier) }

  before { current_api_user.enterprise_roles.create(enterprise: supplier2) }

  describe '#bulk_products' do
    let!(:product3) { create(:product, supplier: supplier2) }

    it "returns a list of products" do
      expect(ProductScopeQuery.new(current_api_user, {}).bulk_products)
        .to include(product, product2, product3)
    end

    it "filters results by supplier" do
      subject = ProductScopeQuery
        .new(current_api_user, { q: { supplier_id_eq: supplier.id } }).bulk_products

      expect(subject).to include(product)
      expect(subject).not_to include(product2, product3)
    end

    describe "by variant category" do
      it "filters results by product category" do
        create(:variant, product: product2, primary_taxon: taxon)

        subject = ProductScopeQuery
          .new(current_api_user, { q: { variants_primary_taxon_id_eq: taxon.id } })
          .bulk_products

        expect(subject).to match_array([product, product2])
        expect(subject).not_to include(product3)
      end

      context "with mutiple variant in the same category" do
        it "doesn't duplicate products" do
          create(:variant, product: product2, primary_taxon: taxon)

          subject = ProductScopeQuery
            .new(current_api_user, { q: { variants_primary_taxon_id_eq: taxon.id } })
            .bulk_products

          expect(subject).to match_array([product, product2])
        end
      end
    end

    it "filters results by import_date" do
      product.variants.first.update_attribute :import_date, 1.day.ago
      product2.variants.first.update_attribute :import_date, 2.days.ago
      product3.variants.first.update_attribute :import_date, 1.day.ago

      subject = ProductScopeQuery
        .new(current_api_user, { import_date: 1.day.ago.to_date.to_s }).bulk_products

      expect(subject).to include(product, product3)
      expect(subject).not_to include(product2)
    end
  end

  describe 'finder functions' do
    describe 'find_product' do
      subject(:query) { ProductScopeQuery.new(current_api_user, { id: product.id }) }
      it 'finds product' do
        expect(query.find_product).to eq(product)
      end
    end

    describe 'find_product_to_be_cloned' do
      subject(:query) { ProductScopeQuery.new(current_api_user, { product_id: product2.id }) }
      it 'finds product to be cloned' do
        expect(query.find_product_to_be_cloned).to eq(product2)
      end
    end
  end

  private

  def supplier_enterprise_user(enterprise)
    user = create(:user)
    user.enterprise_roles.create(enterprise:)
    user
  end
end
