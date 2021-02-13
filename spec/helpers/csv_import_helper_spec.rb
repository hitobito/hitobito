require "spec_helper"

describe CsvImportHelper do
  include UtilityHelper
  include ERB::Util

  context "#csv_field_documentation" do
    it "renders string directly" do
      expect(csv_field_documentation(:first_name, "Only nice names")).to(
        eq "<dt>Vorname</dt><dd>Only nice names</dd>"
      )
    end

    it "renders hashes as options" do
      expect(csv_field_documentation(:gender, "w" => "Girls", "m" => "Gents")).to(
        eq "<dt>Geschlecht</dt><dd><em>w</em> - Girls<br /><em>m</em> - Gents</dd>"
      )
    end
  end

  context "#csv_import_contact_account_attrs" do
    let(:field_mappings) do
      {"Vorname" => "first_name",
       "Nachname" => "last_name",
       "Pfadiname" => "nickname",
       "Titel" => "title",
       "Anrede" => "salutation",
       "Telefonnummer Privat" => "phone_number_privat",
       "Telefonnummer Vater" => "phone_number_vater",
       "Weitere E-Mail Privat" => "additional_email_privat",
       "Social Media Adresse Facebook" => "social_account_facebook",}
    end

    it "returns mapping values" do
      fields = []
      csv_import_contact_account_attrs { |f| fields << f[:key] }
      expect(fields).to eq %w[additional_email_privat
                              phone_number_privat
                              phone_number_vater
                              social_account_facebook]
    end
  end

  context "#csv_import_contact_account_value" do
    let(:person) do
      p = Fabricate(:person)
      p.phone_numbers.create!(label: "Privat", number: "+41 44 123 45 67")
      p.social_accounts.create!(label: "Facebook", name: "foo")
      p.additional_emails.create!(label: "Privat", email: "privat@example.com")
      p.additional_emails.create!(label: "Arbeit", email: "arbeit@example.com")
      p
    end

    it "returns email value" do
      expect(csv_import_contact_account_value(person, "additional_email_arbeit")).to eq "arbeit@example.com"
    end

    it "returns social account value" do
      expect(csv_import_contact_account_value(person, "social_account_facebook")).to eq "foo"
    end

    it "returns nil for non existing social account value" do
      expect(csv_import_contact_account_value(person, "social_account_skype")).to be_nil
    end

    it "returns phone number" do
      expect(csv_import_contact_account_value(person, "phone_number_privat")).to eq "+41 44 123 45 67"
    end
  end
end
