# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "invoice_configs/_provider_fields.html.haml" do
  let(:invoice_config) { invoice_configs(:bottom_layer_one) }
  let(:config) do
    invoice_config.payment_provider_configs.build(payment_provider: "postfinance",
      legacy_25_ebics: legacy_25_ebics)
  end
  let(:form_builder) { StandardFormBuilder.new(:payment_provider_config, config, view, {}) }
  let(:dom) { Capybara::Node::Simple.new(rendered) }

  before { allow(view).to receive_messages(f: form_builder) }

  context "EBICS 3.0 config" do
    let(:legacy_25_ebics) { false }

    it "shows the EBICS version in the fieldset title" do
      render

      expect(dom).to have_content("Postfinance (EBICS 3.0)")
      expect(dom).to have_field("payment_provider_config_legacy_25_ebics",
        type: :hidden, with: "false")
    end
  end

  context "EBICS 2.5 config" do
    let(:legacy_25_ebics) { true }

    it "shows the EBICS version in the fieldset title when the legacy gate is enabled" do
      allow(Settings.invoices.legacy_ebics_25).to receive(:enabled).and_return(true)

      render

      expect(dom).to have_content("Postfinance (EBICS 2.5)")
      expect(dom).to have_field("payment_provider_config_legacy_25_ebics",
        type: :hidden, with: "true")
    end

    it "renders nothing when the legacy gate is disabled" do
      allow(Settings.invoices.legacy_ebics_25).to receive(:enabled).and_return(false)

      render

      expect(rendered).to be_blank
    end
  end
end
