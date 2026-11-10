require "spec_helper"

describe CsvImportHelper do
  include UtilityHelper
  include ERB::Util

  context "#application_person_fields" do
    it "includes id for admins" do
      @can_import_with_id = true
      expect(application_person_fields.map(&:key)).to include("id")
    end

    it "excludes id for non-admins" do
      @can_import_with_id = false
      expect(application_person_fields.map(&:key)).not_to include("id")
    end
  end

  context "#csv_field_documentation" do
    it "renders string directly" do
      expect(csv_field_documentation(:first_name, "Only nice names")).to(
        eq "<dt>Vorname</dt><dd>Only nice names</dd>"
      )
    end

    it "renders hashes as options" do
      expect(csv_field_documentation(:gender, "w" => "Girls", "m" => "Gents")).to(
        eq "<dt>Geschlecht</dt><dd><em>w</em> - Girls<br><em>m</em> - Gents</dd>"
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
       "Telefonnummer Festnetz" => "phone_number_landline",
       "Telefonnummer Andere" => "phone_number_other",
       "Weitere E-Mail Privat" => "additional_email_private",
       "Social Media Adresse Facebook" => "social_account_facebook"}
    end

    it "returns mapping values" do
      fields = []
      csv_import_contact_account_attrs { |f| fields << f[:key] }
      expect(fields).to eq %w[additional_email_private
        phone_number_landline
        phone_number_other
        social_account_facebook]
    end
  end

  context "#csv_import_contact_account_value" do
    let(:person) do
      p = Fabricate(:person)
      p.phone_numbers.create!(category: contact_account_categories(:phone_number_person_landline),
        number: "+41 44 123 45 67")
      p.social_accounts.create!(category: contact_account_categories(:social_account_person_facebook), name: "foo")
      p.additional_emails.create!(category: contact_account_categories(:additional_email_person_private),
        email: "privat@example.com")
      p.additional_emails.create!(category: contact_account_categories(:additional_email_person_work),
        email: "arbeit@example.com")
      p
    end
    let(:user) { person }
    let(:current_ability) { Ability.new(user) }
    let(:row) { {email: person.email} }
    let(:importer) do
      Import::PersonImporter.new([row], groups(:top_group), Group::TopGroup::Member)
        .tap { |importer| importer.user_ability = current_ability }
    end
    let(:entry) { importer.people.first.person }

    def can?(action, subject) = current_ability.can?(action, subject)

    it "returns email value" do
      expect(csv_import_contact_account_value(entry, "additional_email_work")).to eq "arbeit@example.com"
    end

    it "returns social account value" do
      expect(csv_import_contact_account_value(entry, "social_account_facebook")).to eq "foo"
    end

    it "returns nil for non existing social account value" do
      expect(csv_import_contact_account_value(entry, "social_account_x_twitter")).to be_nil
    end

    it "returns phone number" do
      expect(csv_import_contact_account_value(entry, "phone_number_landline")).to eq "+41 44 123 45 67"
    end

    context "for user without show permission on the person" do
      let(:user) { Fabricate(:person) }
      let(:row) { {email: person.email, phone_number_mobile: "+41 77 987 65 43"} }

      it "returns nil for stored value" do
        expect(csv_import_contact_account_value(entry, "phone_number_landline")).to be_nil
      end

      it "returns imported value" do
        expect(csv_import_contact_account_value(entry, "phone_number_mobile")).to eq "+41 77 987 65 43"
      end
    end
  end

  context "#csv_import_attr_value" do
    include FormatHelper
    include ColumnHelper

    let(:group) { groups(:bottom_layer_one) }
    let(:user) { Fabricate(Group::BottomLayer::LocalGuide.name, group: group).person }
    let(:current_ability) { Ability.new(user) }
    let(:row) { {first_name: "Top", last_name: "Leader"} }
    let(:importer) do
      Import::PersonImporter.new([row], group, Group::BottomLayer::Member)
        .tap { |importer| importer.user_ability = current_ability }
    end
    let(:entry) { importer.people.first.person }

    context "with id mapped" do
      let(:row) { {id: people(:top_leader).id.to_s, first_name: "Top"} }

      it "returns id for user without show permission on the person" do
        expect(csv_import_attr_value(entry, "id")).to eq format_attr(people(:top_leader), :id)
      end
    end

    context "for user with show permission on the person" do
      let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: group).person }

      it "returns stored value of person list column" do
        expect(csv_import_attr_value(entry, "town")).to eq "Greattown"
      end

      it "returns no stored value of unregistered attribute" do
        expect(csv_import_attr_value(entry, "additional_information")).to eq "fehlende Berechtigung"
      end

      it "returns no stored value of unregistered public attribute" do
        stub_const("Person::PUBLIC_ATTRS", Person::PUBLIC_ATTRS + [:additional_information])

        expect(csv_import_attr_value(entry, "additional_information")).to eq "fehlende Berechtigung"
      end
    end
  end
end
