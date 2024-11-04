# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe MessageTemplate do
  include ActionDispatch::TestProcess::FixtureFile

  subject { page }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }

  before { sign_in(user) }

  let(:edit_path) { edit_group_invoice_config_path(group) }

  def click_save
    click_button "Rechnungseinstellungen aktualisieren"
  end

  describe "configure through InvoiceConfig" do
    let(:title) { "Neue Vorlage" }
    let(:body) { "Neuer Text" }

    it "is possible to add new templates" do
      visit edit_path
      click_link described_class.model_name.human(count: 2)
      click_link "Eintrag hinzufügen"

      within "#message_templates_fields .fields:last-child" do
        fill_in "Titel", with: title
        fill_in "Text", with: body
      end
      click_save
      expect(page).to have_content("Rechnungseinstellungen wurden erfolgreich aktualisiert")

      message_template = group.reload.invoice_config.message_templates.last
      expect(message_template.title).to eq(title)
      expect(message_template.body).to eq(body)
    end

    it "is possible to remove" do
      visit edit_path
      click_link described_class.model_name.human(count: 2)
      find_all("a.remove_nested_fields").each(&:click)
      click_save

      expect(page).to have_content("Rechnungseinstellungen wurden erfolgreich aktualisiert")
      expect(group.invoice_config.reload.message_templates).to be_none
    end
  end

  describe "use through Invoice" do
    let(:recipient) { people(:bottom_member) }
    let(:new_invoice_path) { new_group_invoice_path(group_id: group, invoice: {recipient_id: recipient.id}) }

    context "with templates" do
      it "allows template selection" do
      end
    end

    context "with no templates" do
      it "does not show the template selection" do
      end
    end
  end
end
