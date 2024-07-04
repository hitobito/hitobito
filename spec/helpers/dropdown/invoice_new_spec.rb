# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Dropdown::InvoiceNew do
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:recipient) { OpenStruct.new(id: 42) }
  let(:dropdown) { Dropdown::InvoiceNew.new(self, people: [recipient]) }
  let(:current_user) { people(:top_leader) }
  let(:finance_group) { current_user.finance_groups.first }
  let(:new_invoice_path) { new_group_invoice_path(group_id: finance_group, invoice: {recipient_id: recipient.id}) }
  let(:invalid_msg) { I18n.t("activerecord.errors.models.invoice_config.not_valid") }

  context "#initialize" do
    it "adds items for finance_groups" do
      expect(dropdown.items).to have(1).item
      item = dropdown.items.first
      expect(item.url).to eq new_invoice_path
      expect(item.disabled_msg).to eq nil
    end

    it "adds disabled item for finance_group with invalid invoice_config" do
      InvoiceConfig.update_all(payment_slip: "qr", payee: "not-enough-lines")
      expected_path = new_invoice_path
      expect(dropdown.items).to have(1).item
      item = dropdown.items.first
      expect(item.url).to eq expected_path
      expect(item.disabled_msg).to eq invalid_msg
    end
  end

  context "#button_or_dropdown" do
    context "with multiple finance_groups" do
      it "renders equal as #to_s" do
        Group::BottomLayer::Member.permissions << :finance
        Fabricate(:"Group::BottomLayer::Member", person: current_user, group: groups(:bottom_layer_one))
        expect(current_user.reload.finance_groups).to have(2).items

        expect(dropdown.button_or_dropdown).to eq dropdown.to_s
      end
    end

    context "with single finance_group" do
      let(:html) { Capybara::Node::Simple.new(dropdown.button_or_dropdown) }

      it "with valid invoice_config renders link" do
        expect(finance_group.invoice_config).to be_valid

        expect(html).to have_link("Rechnung erstellen", href: new_invoice_path)
      end

      it "with invalid invoice_config renders disabled link" do
        finance_group.invoice_config.update_columns(payment_slip: "qr", payee: "not-enough-lines")
        expect(finance_group.reload.invoice_config).to be_invalid

        expect(html).not_to have_link(href: new_invoice_path)
        expect(html).to have_selector "div[title='#{invalid_msg}'] a.btn.disabled", text: "Rechnung erstellen"
      end
    end
  end
end
