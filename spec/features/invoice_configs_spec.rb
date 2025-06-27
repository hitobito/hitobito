# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe :invoice_configs, js: true do
  include ActionDispatch::TestProcess::FixtureFile

  subject { page }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }

  before { sign_in(user) }

  let(:edit_path) { edit_group_invoice_config_path(group) }

  context "logo_position" do
    it "has options for logo_position" do
      visit edit_path
      click_link "Layout"

      logo_position_options = all('select[name="invoice_config[logo_position]"] option')
        .reduce({}) { |options, option| options.merge(option.value.to_sym => option.text) }

      expect(logo_position_options).to match(
        disabled: "Kein Logo",
        left: "Links",
        right: "Rechts"
      )
    end
  end

  context "logo" do
    context "when logo is not present" do
      before do
        expect(group.invoice_config.logo.attached?).to eq false
        visit edit_path
        click_link "Layout"
      end

      it "has no remove_logo checkbox" do
        expect(page).to have_no_selector "input[type='checkbox'][name='invoice_config[remove_logo]']"
      end

      it 'requires a logo when logo_position is not "Kein Logo"' do
        select "Rechts", from: "invoice_config[logo_position]"
        click_button "Rechnungseinstellungen aktualisieren"

        expect(page).to have_content "Logo muss angegeben werden, wenn eine Logoposition gewählt ist"
        click_link "Layout"
        expect(page).to have_selector "#invoice_config_logo.is-invalid"
      end

      it "attaches logo when file is selected" do
        attach_file "invoice_config[logo]", file_fixture("images/logo.png")
        click_button "Rechnungseinstellungen aktualisieren"

        expect(page).to have_content "Rechnungseinstellungen wurden erfolgreich aktualisiert"
        expect(group.reload.invoice_config.logo.attached?).to eq true
      end
    end

    context "when logo is present" do
      before do
        group.invoice_config.logo.attach fixture_file_upload("images/logo.png")
        expect(group.invoice_config.logo.attached?).to eq true
        visit edit_path
        click_link "Layout"
      end

      it "has remove_logo checkbox" do
        expect(page).to have_selector "input[type='checkbox'][name='invoice_config[remove_logo]']"
      end

      it "removes logo when remove_logo is checked" do
        check "invoice_config[remove_logo]"
        click_button "Rechnungseinstellungen aktualisieren"
        expect(page).to have_content "Rechnungseinstellungen wurden erfolgreich aktualisiert"
        expect(group.reload.invoice_config.logo.attached?).to eq false
      end
    end
  end

  context "custom content" do
    before do
      visit edit_path
      click_link "E-Mail"
      expect(page).to have_text "E-Mail Vorlage"
    end

    it "is possible to add and remove one custom content" do
      custom_contents(:content_invoice_notification).update!(placeholders_required: nil)

      expect(page).to have_text "Diese E-Mail Vorlage wird beim versenden von Rechnungen verwendet. Wenn keine E-Mail Vorlage hinterlegt wird, wird die globale E-Mail Vorlage verwendet."
      click_link "Eintrag hinzufügen"
      expect(page).to have_text "Betreff"
      expect(page).to have_text "Inhalt"
      expect(page).to have_text "Verfügbare Platzhalter: {invoice-items}, {invoice-total}, {payment-information}, {recipient-name}, {group-name}, {group-address}, {invoice-number}"
      click_button "Rechnungseinstellungen aktualisieren"
      expect(page).to have_text "Rechnungseinstellungen wurden erfolgreich aktualisiert"

      expect(group.invoice_config.custom_content).not_to be_nil

      # remove again
      visit edit_path
      click_link "E-Mail"
      click_link "E-Mail Vorlage entfernen"
      click_button "Rechnungseinstellungen aktualisieren"
      expect(page).to have_text "Rechnungseinstellungen wurden erfolgreich aktualisiert"

      expect(group.invoice_config.reload.custom_content).to be_nil
    end

    it "is not possible to add multiple custom contents" do
      click_link "Eintrag hinzufügen"
      expect(page).to have_no_text "Eintrag hinzufügen"
    end

    it "link_to_add appears again when removing custom content" do
      click_link "Eintrag hinzufügen"
      expect(page).to have_no_text "Eintrag hinzufügen"
      click_link "E-Mail Vorlage entfernen"
      expect(page).to have_text "Eintrag hinzufügen"
    end
  end
end
