# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe MessageTemplate, js: true do
  include ActionDispatch::TestProcess::FixtureFile

  subject { page }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:invoice_config) { group.invoice_config }

  before { sign_in(user) }

  describe "configure in InvoiceConfig" do
    let(:edit_path) { edit_group_invoice_config_path(group) }
    let(:title) { "Neue Vorlage" }
    let(:body) { "Neuer Text" }

    def click_save
      click_button "Rechnungseinstellungen aktualisieren"
    end

    before do
      visit edit_path
      click_link described_class.model_name.human(count: 2)
    end

    it "allows to add new templates" do
      click_link "Eintrag hinzufügen"

      within "#message_templates_fields .fields:last-child" do
        fill_in "Titel", with: title
        fill_in "Text", with: body
      end
      click_save
      expect(page).to have_content("Rechnungseinstellungen wurden erfolgreich aktualisiert")

      message_template = invoice_config.reload.message_templates.last
      expect(message_template.title).to eq(title)
      expect(message_template.body).to eq(body)
    end

    it "allows to remove templates" do
      expect do
        find("#message_templates_fields .fields:last-child a.remove_nested_fields").click
        click_save
        expect(page).to have_content("Rechnungseinstellungen wurden erfolgreich aktualisiert")
      end.to change { invoice_config.reload.message_templates.count }.from(2).to(1)
    end
  end

  describe "use in Invoice" do
    let(:recipient) { people(:bottom_member) }
    let(:new_invoice_path) { new_group_invoice_path(group_id: group, invoice: {recipient_id: recipient.id}) }
    let(:message_templates) { group.invoice_config.message_templates }

    context "with some templates" do
      it "allows template selection" do
        visit new_invoice_path
        expect(invoice_config.message_templates.count).to be(2)
        expect(page).to have_content(described_class.model_name.human)
        expect(page).to have_field(:invoice_title, with: "")
        expect(page).to have_field(:invoice_description, with: "")

        message_templates.each do |message_template|
          select(message_template.title, from: :invoice_message_template_id)
          expect(page).to have_field(:invoice_title, with: message_template.title)
          expect(page).to have_field(:invoice_description, with: message_template.body)
        end

        select("", from: :invoice_message_template_id)
        expect(page).to have_field(:invoice_title, with: "")
        expect(page).to have_field(:invoice_description, with: "")
      end
    end

    context "with no templates" do
      it "does not show the template selection" do
        invoice_config.message_templates.delete_all
        visit new_invoice_path
        expect(page).not_to have_content(described_class.model_name.human)
      end
    end
  end
end
