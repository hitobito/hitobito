# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ContactableHelper, type: :helper do
  include FormatHelper
  include I18nHelper
  include UtilityHelper
  include ColumnHelper
  before do
    allow(helper).to receive(:t).with("contactable.label_placeholder").and_return("Type")
  end

  let(:additional_email) {
    people(:top_leader).additional_emails.build(email: "other@example.com")
  }
  let(:form) { StandardFormBuilder.new(:additional_email, additional_email, self, {}) }

  describe "#contact_method_category_field" do
    let(:categories) { ContactAccountCategory.for("AdditionalEmail", "Person") }

    def available_options(html_string)
      Capybara.string(html_string).all(:option).map(&:value)
    end

    it "has an option for every category of this contact_account_type/contactable_type" do
      result = helper.contact_method_category_field(form)
      expect(result).to have_selector("select#additional_email_category_id")

      expect(available_options(result)).to match_array categories.map { |c| c.id.to_s }.push("")
    end

    it "includes a blank option for a new record" do
      result = helper.contact_method_category_field(form)

      expect(result).to have_selector("option[value='']")
    end

    it "does not include a blank option for a persisted record" do
      additional_email.category = categories.first
      additional_email.save!
      result = helper.contact_method_category_field(form)

      expect(result).not_to have_selector("option[value='']")
    end

    it "the current value is selected" do
      additional_email.category = categories.third
      result = helper.contact_method_category_field(form)

      expect(result)
        .to have_selector("option[value='#{categories.third.id}'][selected='selected']")
    end
  end

  describe "#contact_method_label_field" do
    it "renders a plain freetext input, without any typeahead" do
      result = helper.contact_method_label_field(form)

      expect(result).to have_selector("input#additional_email_label")
      expect(result).not_to have_selector("input[data-provide='typeahead']")
    end

    it "the current value is filled in" do
      additional_email.label = "Ferienwohnung"
      result = helper.contact_method_label_field(form)

      expect(result).to have_selector("input#additional_email_label[value='Ferienwohnung']")
    end
  end
end
