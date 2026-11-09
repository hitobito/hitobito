# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

RSpec.shared_examples "contact account resource" do |fabricator:, category_fixture:|
  let(:category) { contact_account_categories(category_fixture) }
  let!(:contact_account) do
    Fabricate(fabricator, contactable: person, category:, public: false)
  end
  let(:resource_type) { described_class.type }

  def serialized_contact_account
    jsonapi_data.index_by(&:id)[contact_account.id]
  end

  context "category_name" do
    it "is not rendered without extra_fields" do
      render
      expect(serialized_contact_account.key?(:category_name)).to be(false)
    end

    context "when requested via extra_fields" do
      before { params[:extra_fields] = {resource_type => "category_name"} }

      it "returns the translated category name" do
        render
        expect(serialized_contact_account[:category_name]).to eq(category.name)
      end

      it "returns the category name in the current locale" do
        I18n.with_locale(:it) { render }
        expect(serialized_contact_account[:category_name])
          .to eq(I18n.with_locale(:it) { category.name })
      end

      it "eager loads categories and their translations" do
        expect { render }.to make.db_queries.with(
          "ContactAccountCategory Load" => 1,
          "ContactAccountCategory::Translation Load" => 1
        )
      end
    end

    context "with sparse fieldsets" do
      before { params[:fields] = {resource_type => "public,category_name"} }

      it "does not render category_name" do
        render
        node = serialized_contact_account
        expect(node.key?(:public)).to be(true)
        expect(node.key?(:category_name)).to be(false)
      end
    end
  end
end
