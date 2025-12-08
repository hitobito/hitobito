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
  let(:finance_group) { Group.find(Ability.new(current_user).user_finance_layer_ids[0]) }
  let(:ability) { Ability.new(current_user) }
  let(:new_invoice_path) { new_group_invoice_path(group_id: finance_group, invoice: {recipient_id: recipient.id}) }
  let(:invalid_msg) { I18n.t("activerecord.errors.models.invoice_config.not_valid") }

  context "#initialize" do
    before { allow(self).to receive(:current_ability).and_return(ability) }

    describe "filter params" do
      let(:filter) { {range: :foo, filters: :bar} }
      let(:group) { groups(:top_group) }

      def query_from_params(filter:)
        dropdown = Dropdown::InvoiceNew.new(self, people: [recipient], group:, filter:)
        Rack::Utils.parse_query(URI.parse(dropdown.items.first.url).query)
      end

      it "reads filter from hash" do
        query = query_from_params(filter: filter)
        expect(query["filter[range]"]).to eq "foo"
        expect(query["filter[filters]"]).to eq "bar"
      end

      it "reads filter from hash from string keys" do
        query = query_from_params(filter: filter.stringify_keys)
        expect(query["filter[range]"]).to eq "foo"
        expect(query["filter[filters]"]).to eq "bar"
      end

      it "reads filter from ActionController params" do
        query = query_from_params(filter: ActionController::Parameters.new(filter))
        expect(query["filter[range]"]).to eq "foo"
        expect(query["filter[filters]"]).to eq "bar"
      end
    end

    it "adds items for finance_groups" do
      expect(dropdown.items).to have(1).item
      item = dropdown.items.first
      expect(item.url).to eq new_invoice_path
      expect(item.disabled_msg).to eq nil
    end

    it "adds disabled item for finance_group with invalid invoice_config" do
      InvoiceConfig.update_all(payment_slip: "qr", payee_name: nil)
      expected_path = new_invoice_path
      expect(dropdown.items).to have(1).item
      item = dropdown.items.first
      expect(item.url).to eq expected_path
      expect(item.disabled_msg).to eq invalid_msg
    end
  end

  context "#button_or_dropdown" do
    context "with multiple finance_groups" do
      before do
        Fabricate(Group::BottomLayer::Member.sti_name, person: current_user, group: groups(:bottom_layer_one))
        allow(Group::BottomLayer::Member).to receive(:permissions).and_return([:finance])
        allow(self).to receive(:current_ability).and_return(ability)
      end

      it "renders equal as #to_s" do
        expect(dropdown.button_or_dropdown).to eq dropdown.to_s
      end
    end

    context "with single finance_group" do
      let(:html) { Capybara::Node::Simple.new(dropdown.button_or_dropdown) }

      before { allow(self).to receive(:current_ability).and_return(ability) }

      it "with valid invoice_config renders link" do
        expect(finance_group.invoice_config).to be_valid

        expect(html).to have_link("Rechnung erstellen", href: new_invoice_path)
      end

      it "with invalid invoice_config renders disabled link" do
        finance_group.invoice_config.update_columns(payment_slip: "qr", payee_name: nil)
        expect(finance_group.reload.invoice_config).to be_invalid

        expect(html).not_to have_link(href: new_invoice_path)
        expect(html).to have_selector "div[title='#{invalid_msg}'] a.btn.disabled", text: "Rechnung erstellen"
      end
    end
  end
end
