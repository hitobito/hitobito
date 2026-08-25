# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ContactAccountCategoryMigrationJob do
  before do
    [:additional_addresses, :additional_emails, :phone_numbers, :social_accounts].each do |table|
      ActiveRecord::Base.connection.change_column_null(table, :category_id, true)
    end
  end

  let(:person) { people(:top_leader) }

  def run = described_class.new.perform

  # category is required by validation now, but these examples simulate
  # not-yet-migrated data -- build normally (any category satisfies presence),
  # then null it out via update_column, bypassing both the validation and the
  # loosened DB constraint above.
  def uncategorize!(record)
    record.update_column(:category_id, nil)
    record
  end

  # Exercises the generic label-matching/other-fallback behavior of
  # ContactAccountCategoryMigrationJob against a concrete contact_account_type/
  # contactable_type pairing.
  #
  # opts:
  #   factory:              fabricator name, e.g. :phone_number
  #   contact_account_type: e.g. "PhoneNumber"
  #   contactable_type:     "Person" or "Group"
  #   contactable:          -> { ... } returning the contactable to build entries on
  #   other_category:       fixture key of the "other" category for this combination
  #   label_mapping:        optional {label:, category:, key:} -- a label present in
  #                         LABEL_KEY_MAPPING for this combination, the fixture key of
  #                         the category it maps to, and that category's own key.
  #                         Omitted for combinations with no mapping at all (e.g.
  #                         AdditionalAddress/Group).
  shared_examples "migrates label to category" do |opts|
    let(:factory) { opts.fetch(:factory) }
    let(:contact_account_type) { opts.fetch(:contact_account_type) }
    let(:contactable_type) { opts.fetch(:contactable_type) }
    let(:contactable) { instance_exec(&opts.fetch(:contactable)) }
    let(:other_category) { contact_account_categories(opts.fetch(:other_category)) }

    if (label_mapping = opts[:label_mapping])
      it "matches a known label case and whitespace insensitively and clears the label" do
        record = uncategorize!(Fabricate(factory, contactable:, label: "  #{label_mapping[:label].upcase}  "))

        run

        expect(record.reload.category).to eq contact_account_categories(label_mapping[:category])
        expect(record.label).to be_nil
      end

      it "also matches when the label is already the category's own key" do
        record = uncategorize!(Fabricate(factory, contactable:, label: label_mapping[:key]))

        run

        expect(record.reload.category).to eq contact_account_categories(label_mapping[:category])
        expect(record.label).to be_nil
      end

      it "falls back to other when the mapped category itself no longer exists" do
        ContactAccountCategory.where(contact_account_type:, contactable_type:, key: label_mapping[:key]).delete_all
        record = uncategorize!(Fabricate(factory, contactable:, label: label_mapping[:label]))

        run

        expect(record.reload.category).to eq other_category
        expect(record.label).to eq label_mapping[:label]
      end
    end

    it "falls back to the other category and keeps the label when nothing matches" do
      record = uncategorize!(Fabricate(factory, contactable:, label: "Ferienwohnung"))

      run

      expect(record.reload.category).to eq other_category
      expect(record.label).to eq "Ferienwohnung"
    end

    it "sets other for rows with a blank label" do
      record = uncategorize!(Fabricate(factory, contactable:, label: nil))

      run

      expect(record.reload.category).to eq other_category
    end

    it "treats a whitespace-only label the same as a blank one" do
      record = uncategorize!(Fabricate(factory, contactable:, label: "   "))

      run

      expect(record.reload.category).to eq other_category
    end

    it "never touches a row that already has a category" do
      record = Fabricate(factory, contactable:, category_id: other_category.id, label: "Mobil")

      run

      expect(record.reload.category).to eq other_category
      expect(record.label).to eq "Mobil"
    end
  end

  describe "used_for_invoices" do
    it "assigns the category and clears the label when it exactly matches the category's name" do
      email = uncategorize!(person.additional_emails.create!(email: "invoices@example.com",
        label: "  RECHNUNGSADRESSE  ", invoices: true,
        category: contact_account_categories(:additional_email_person_other)))

      run

      expect(email.reload.category).to eq contact_account_categories(:additional_email_person_invoices)
      expect(email.label).to be_nil
      expect(email.invoices).to eq true
    end

    it "assigns the category but keeps the label when it doesn't exactly match the category's name" do
      email = uncategorize!(person.additional_emails.create!(email: "invoices@example.com", label: "Rechnung",
        invoices: true, category: contact_account_categories(:additional_email_person_other)))

      run

      expect(email.reload.category).to eq contact_account_categories(:additional_email_person_invoices)
      expect(email.label).to eq "Rechnung"
      expect(email.invoices).to eq true
    end

    it "leaves category nil and keeps the label when no used_for_invoices or other category exists" do
      other_category = contact_account_categories(:additional_email_person_private)
      ContactAccountCategory
        .where(contact_account_type: "AdditionalEmail", contactable_type: "Person")
        .where("used_for_invoices OR key = 'other'").delete_all

      email = uncategorize!(person.additional_emails.create!(email: "invoices@example.com", label: "Rechnung",
        invoices: true, category: other_category))

      run

      expect(email.reload.category_id).to be_nil
      expect(email.label).to eq "Rechnung"
      expect(email.invoices).to eq true
    end

    it "prioritizes the used_for_invoices category even when the label matches something else, but keeps the label" do
      email = uncategorize!(person.additional_emails.create!(email: "invoices@example.com", label: "Arbeit",
        invoices: true, category: contact_account_categories(:additional_email_person_other)))

      run

      expect(email.reload.category).to eq contact_account_categories(:additional_email_person_invoices)
      expect(email.label).to eq "Arbeit"
    end

    it "falls through to the other category when the used_for_invoices category is missing but other exists" do
      ContactAccountCategory
        .where(contact_account_type: "AdditionalEmail", contactable_type: "Person", used_for_invoices: true)
        .delete_all

      email = uncategorize!(person.additional_emails.create!(email: "invoices@example.com", label: "Rechnung",
        invoices: true, category: contact_account_categories(:additional_email_person_private)))

      run

      expect(email.reload.category).to eq contact_account_categories(:additional_email_person_other)
      expect(email.label).to eq "Rechnung"
    end

    it "assigns the used_for_invoices category for AdditionalAddress on a Group" do
      group = groups(:top_group)
      address = uncategorize!(Fabricate(:additional_address, contactable: group, label: "Rechnungsadresse",
        invoices: true))

      run

      expect(address.reload.category).to eq contact_account_categories(:additional_address_group_invoices)
      expect(address.label).to be_nil
    end
  end

  describe "label matching" do
    it "handles multiple different labels within the same run without cross-contamination" do
      other_category = contact_account_categories(:phone_number_person_other)
      mobile = uncategorize!(person.phone_numbers.create!(number: "+41 78 000 00 08", label: "Mobil",
        category: other_category))
      landline = uncategorize!(person.phone_numbers.create!(number: "+41 78 000 00 09", label: "Privat",
        category: other_category))
      unmapped = uncategorize!(person.phone_numbers.create!(number: "+41 78 000 00 10", label: "Ferienwohnung",
        category: other_category))

      run

      expect(mobile.reload.category).to eq contact_account_categories(:phone_number_person_mobile)
      expect(landline.reload.category).to eq contact_account_categories(:phone_number_person_landline)
      expect(unmapped.reload.category).to eq contact_account_categories(:phone_number_person_other)
    end

    context "PhoneNumber on Person" do
      it_behaves_like "migrates label to category",
        factory: :phone_number,
        contact_account_type: "PhoneNumber",
        contactable_type: "Person",
        contactable: -> { people(:top_leader) },
        other_category: :phone_number_person_other,
        label_mapping: {label: "Mobil", category: :phone_number_person_mobile, key: "mobile"}
    end

    context "PhoneNumber on Group" do
      it_behaves_like "migrates label to category",
        factory: :phone_number,
        contact_account_type: "PhoneNumber",
        contactable_type: "Group",
        contactable: -> { groups(:top_group) },
        other_category: :phone_number_group_other,
        label_mapping: {label: "Arbeit", category: :phone_number_group_office, key: "office"}
    end

    context "SocialAccount on Person" do
      it_behaves_like "migrates label to category",
        factory: :social_account,
        contact_account_type: "SocialAccount",
        contactable_type: "Person",
        contactable: -> { people(:top_leader) },
        other_category: :social_account_person_other,
        label_mapping: {label: "Facebook", category: :social_account_person_facebook, key: "facebook"}
    end

    context "SocialAccount on Group" do
      it_behaves_like "migrates label to category",
        factory: :social_account,
        contact_account_type: "SocialAccount",
        contactable_type: "Group",
        contactable: -> { groups(:top_group) },
        other_category: :social_account_group_other,
        label_mapping: {label: "Facebook", category: :social_account_group_facebook, key: "facebook"}
    end

    context "AdditionalEmail on Person" do
      it_behaves_like "migrates label to category",
        factory: :additional_email,
        contact_account_type: "AdditionalEmail",
        contactable_type: "Person",
        contactable: -> { people(:top_leader) },
        other_category: :additional_email_person_other,
        label_mapping: {label: "Privat", category: :additional_email_person_private, key: "private"}
    end

    context "AdditionalEmail on Group" do
      it_behaves_like "migrates label to category",
        factory: :additional_email,
        contact_account_type: "AdditionalEmail",
        contactable_type: "Group",
        contactable: -> { groups(:top_group) },
        other_category: :additional_email_group_other,
        label_mapping: {label: "Arbeit", category: :additional_email_group_office, key: "office"}
    end

    context "AdditionalAddress on Person" do
      it_behaves_like "migrates label to category",
        factory: :additional_address,
        contact_account_type: "AdditionalAddress",
        contactable_type: "Person",
        contactable: -> { people(:top_leader) },
        other_category: :additional_address_person_other,
        label_mapping: {label: "Arbeit", category: :additional_address_person_work, key: "work"}
    end

    context "AdditionalAddress on Group" do
      it_behaves_like "migrates label to category",
        factory: :additional_address,
        contact_account_type: "AdditionalAddress",
        contactable_type: "Group",
        contactable: -> { groups(:top_group) },
        other_category: :additional_address_group_other
    end

    # AdditionalAddress/Group has no entry at all in LABEL_KEY_MAPPING (core never
    # needed one), so it's the cleanest place to prove key/translation matching work
    # independently of the mapping table.
    context "matching without any LABEL_KEY_MAPPING coverage (AdditionalAddress on Group)" do
      let(:group) { groups(:top_group) }

      it "matches a label equal to a category's own key, case insensitively" do
        address = uncategorize!(Fabricate(:additional_address, contactable: group, label: "OTHER"))

        run

        expect(address.reload.category).to eq contact_account_categories(:additional_address_group_other)
        expect(address.label).to be_nil
      end

      it "matches a label equal to a category's translated name" do
        address = uncategorize!(Fabricate(:additional_address, contactable: group, label: "andere"))

        run

        expect(address.reload.category).to eq contact_account_categories(:additional_address_group_other)
        expect(address.label).to be_nil
      end
    end

    context "translation matching (partial matches assign the category, only exact matches clear the label)" do
      it "matches a translation case and whitespace insensitively and clears the label" do
        # AdditionalEmail/Group has no "büro" entry in LABEL_KEY_MAPPING (only "arbeit" does),
        # so this can only be resolved via the "office" category's own German name.
        email = uncategorize!(Fabricate(:additional_email, contactable: groups(:top_group),
          label: "  BÜRO  "))

        run

        expect(email.reload.category).to eq contact_account_categories(:additional_email_group_office)
        expect(email.label).to be_nil
      end

      it "matches an exact translation containing punctuation" do
        account = uncategorize!(Fabricate(:social_account, contactable: people(:top_leader),
          label: "X (Twitter)"))

        run

        expect(account.reload.category).to eq contact_account_categories(:social_account_person_x_twitter)
        expect(account.label).to be_nil
      end

      it "assigns the category on a partial translation match but keeps the label" do
        # "Büro" (office) is a real translation, but this label is only a compound
        # phrase containing it, not an exact match -- the category is still
        # assigned, but the label carries more information than the category
        # alone, so it's kept rather than cleared.
        email = uncategorize!(Fabricate(:additional_email, contactable: groups(:top_group),
          label: "Neues Büro Zürich"))

        run

        expect(email.reload.category).to eq contact_account_categories(:additional_email_group_office)
        expect(email.label).to eq "Neues Büro Zürich"
      end

      it "resolves a label matching multiple categories' translations by category order, not string position" do
        # "Arbeit" (work) appears earlier in the string, but "private" has a lower
        # :position than "work" for AdditionalEmail/Person -- category order wins,
        # not where the match happens to start in the label.
        email = uncategorize!(Fabricate(:additional_email, contactable: people(:top_leader),
          label: "Arbeit (Privat)"))

        run

        expect(email.reload.category).to eq contact_account_categories(:additional_email_person_private)
        expect(email.label).to eq "Arbeit (Privat)"
      end
    end
  end
end
