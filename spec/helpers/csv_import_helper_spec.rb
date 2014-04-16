require 'spec_helper'

describe CsvImportHelper do
  context '#csv_field_documentation' do
    it 'renders string directly' do
      csv_field_documentation(:first_name, 'Only nice names').should
      eq '<dt>Vorname</dt><dd>Only nice names</dd>'
    end

    it 'renders hashes as options' do
      csv_field_documentation(:gender, 'w' => 'Girls', 'm' => 'Gents').should
      eq '<dt>Geschlecht</dt><dd><em>w</em> - Girls<br/><em>m</em> - Gents</dd>'
    end
  end

  context '#csv_import_contact_account_attrs' do
    let(:field_mappings) do
      { "Vorname"=>"first_name",
        "Nachname"=>"last_name",
        "Pfadiname"=>"nickname",
        "Titel"=>"title",
        "Anrede"=>"salutation",
        "Telefonnummer Privat"=>"phone_number_privat",
        "Telefonnummer Vater"=>"phone_number_vater",
        "Weitere E-Mail Privat"=>"additional_email_privat",
        "Social Media Adresse Facebook"=>"social_account_facebook" }
    end

    it 'returns mapping values' do
      fields = []
      csv_import_contact_account_attrs { |f| fields << f[:key] }
      fields.should eq %w(additional_email_privat
                          phone_number_privat
                          phone_number_vater
                          social_account_facebook)
    end
  end

  context '#csv_import_contact_account_value' do
    let(:person) do
      p = Fabricate(:person)
      p.phone_numbers.create!(label: 'Privat', number: '123')
      p.social_accounts.create!(label: 'Facebook', name: 'foo')
      p.additional_emails.create!(label: 'Privat', email: 'privat@example.com')
      p.additional_emails.create!(label: 'Arbeit', email: 'arbeit@example.com')
      p
    end

    it 'returns email value' do
      csv_import_contact_account_value(person, 'additional_email_arbeit').should eq 'arbeit@example.com'
    end

    it 'returns social account value' do
      csv_import_contact_account_value(person, 'social_account_facebook').should eq 'foo'
    end

    it 'returns nil for non existing social account value' do
      csv_import_contact_account_value(person, 'social_account_skype').should be_nil
    end

    it 'returns phone number' do
      csv_import_contact_account_value(person, 'phone_number_privat').should eq '123'
    end
  end
end
