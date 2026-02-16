# frozen_string_literal: true

#  Copyright (c) 2012-2022, insieme Schweiz. This file is part of
#  hitobito_insieme and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level # directory or at
#  http# s://github.com/hitobi# to/hitobito_insieme.
#
require "spec_helper"

describe ContactableHelper, type: :helper do
  include FormatHelper
  include UtilityHelper
  include ColumnHelper
  before { allow(helper).to receive(:t).with(".placeholder_type").and_return("Type") }

  let(:additional_email) {
    people(:top_leader).additional_emails.build(email: "other@example.com")
  }
  let(:form) { StandardFormBuilder.new(:additional_email, additional_email, self, {}) }

  describe "#contact_method_label_select" do
    standard_options = AdditionalEmail.predefined_labels

    def available_options(html_string)
      Capybara.string(html_string).all(:option).map(&:value)
    end

    it "has the expected options" do
      result = helper.contact_method_label_select(form)
      expect(result).to have_selector("select#additional_email_translated_label")

      expect(available_options(result)).to match_array standard_options
    end

    it "the current value is selected" do
      additional_email.label = standard_options.third
      result = helper.contact_method_label_select(form)

      expect(result)
        .to have_selector("option[value='#{standard_options.third}'][selected='selected']")
    end

    it "includes current value as option" do
      additional_email.label = "nonstandard_value"
      result = helper.contact_method_label_select(form)

      expect(available_options(result)).to match_array [*standard_options, "nonstandard_value"]
    end

    it "the nonstandard value is selected" do
      additional_email.label = "nonstandard_value"
      result = helper.contact_method_label_select(form)

      expect(result).to have_selector("option[value='nonstandard_value'][selected='selected']")
    end
  end

  describe "#contact_method_label_text_field" do
    it "creates an input field with typeahead data attributes" do
      result = helper.contact_method_label_text_field(form)

      expect(result).to have_selector("input#additional_email_translated_label")
      expect(result).to have_selector("input[data-provide='typeahead']")
    end

    it "includes available labels as data source" do
      result = helper.contact_method_label_text_field(form)
      parsed = Capybara.string(result)
      input = parsed.find("input[name='additional_email[translated_label]']")

      expect(input["data-source"]).to eq(AdditionalEmail.available_labels.to_json)
    end
  end

  describe "#contact_method_label_field" do
    it "returns a text field when feature gate is enabled" do
      allow(FeatureGate).to receive(:enabled?)
        .with("additional_email.free_text_label")
        .and_return(true)

      result = helper.contact_method_label_field(form)

      expect(result).not_to have_selector("select#additional_email_translated_label")
      expect(result).to have_selector("input#additional_email_translated_label")
    end

    it "returns a select field when feature gate is disabled" do
      allow(FeatureGate).to receive(:enabled?)
        .with("additional_email.free_text_label")
        .and_return(false)

      result = helper.contact_method_label_field(form)

      expect(result).not_to have_selector("input#additional_email_translated_label")
      expect(result).to have_selector("select#additional_email_translated_label")
    end
  end
end
