# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"
require "csv"

describe Person::CsvImportsController do
  include CsvImportMacros

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  before { sign_in(person) }

  describe "POST #define_mapping" do
    it "populates flash, data and columns" do
      file = Rack::Test::UploadedFile.new(path(:utf8), "text/csv")
      post :define_mapping, params: {group_id: group.id, csv_import: {file: file}}
      parser = assigns(:parser)
      expect(parser.to_csv).to be_present
      expect(parser.headers).to be_present
      expect(flash[:notice]).to match(/1 Datensatz erfolgreich gelesen/)
    end

    it "redisplays form if failed to parse csv" do
      file = Rack::Test::UploadedFile.new(path(:utf8, :ods), "text/csv")
      post :define_mapping, params: {group_id: group.id, csv_import: {file: file}}
      expect(flash[:data]).not_to be_present
      expect(flash[:alert]).to match(/Fehler beim Lesen von utf8.ods/)
      is_expected.to redirect_to new_group_csv_imports_path(group)
    end

    it "renders form when submitted without file" do
      post :define_mapping, params: {group_id: group.id}
      expect(flash[:alert]).to eq "Bitte wählen Sie eine gültige CSV Datei aus."
      is_expected.to redirect_to new_group_csv_imports_path(group)
    end

    context "with person number column" do
      render_views

      let(:data) { generate_csv(%w[Personennummer Vorname], [person.id, "foo"]) }
      let(:dom) { Capybara::Node::Simple.new(response.body) }
      let(:select) { dom.find("select[data-header='Personennummer']") }

      it "maps it to id for admins" do
        post :define_mapping, params: {group_id: group.id, data: data}
        expect(select.find("option[selected]").value).to eq "id"
      end

      context "as non-admin" do
        let(:group) { groups(:bottom_layer_one) }
        let(:person) { Fabricate(Group::BottomLayer::Leader.name, group: group).person }

        it "does not offer id" do
          post :define_mapping, params: {group_id: group.id, data: data}
          expect(select).not_to have_css("option[value='id']")
          expect(select).not_to have_css("option[selected]")
        end
      end
    end
  end

  describe "POST preview" do
    let(:data) { File.read(path(:utf8)) }
    let(:role_type) { "Group::TopGroup::Leader" }
    let(:mapping) { {Vorname: "first_name", Nachname: "last_name", Geburtsdatum: "birthday"} }
    let(:required_params) { {group_id: group.id, data: data, role_type: role_type} }

    it "informs about newly imported person" do
      post :preview, params: required_params.merge(field_mappings: {Vorname: "first_name", Nachname: "last_name"})
      expect(flash[:notice]).to eq ["1 Person (Leader) wird neu importiert."]
      is_expected.to render_template(:preview)
    end

    it "renders preview even when field_mapping is missing" do
      post :preview, params: required_params
      expect(flash[:alert]).to eq ["1 Person (Leader) wird nicht importiert.",
        "Zeile 1: Bitte geben Sie einen Namen ein"]
      is_expected.to render_template(:preview)
    end

    it "informs about duplicates in assignment" do
      post :preview, params: required_params.merge(field_mappings: {Vorname: "first_name", Nachname: "first_name"})
      expect(flash[:alert]).to eq "Vorname wurde mehrfach zugewiesen."
      is_expected.to render_template(:define_mapping)
    end

    it "rerenders form when role_type is missing" do
      post :preview, params: {group_id: group.id, data: data}
      expect(flash.now[:alert]).to eq "Role muss ausgefüllt werden."
      is_expected.to render_template(:define_mapping)
    end

    context "csv data matches multiple people" do
      let(:data) { generate_csv(%w[Vorname Email], %w[foo foo@bar.net]) }

      it "reports error if multiple candidates for doublettes are found" do
        Fabricate(:person, first_name: "bar", email: "foo@bar.net")
        Fabricate(:person, first_name: "foo", email: "bar@bar.net")
        post :preview, params: required_params.merge(field_mappings: {Vorname: "first_name", Email: "email"})
        expect(flash[:alert]).to eq ["1 Person (Leader) wird nicht importiert.",
          "Zeile 1: 2 Treffer in Duplikatserkennung."]
      end
    end

    context "csv data matches existing person" do
      render_views

      let(:group) { groups(:bottom_layer_one) }
      let(:role_type) { "Group::BottomLayer::Member" }
      let(:headers) { %w[Vorname Nachname Uebername Ort Geburtstag Angaben Telefon Mobile Tags] }
      let(:field_mappings) do
        {Vorname: "first_name", Nachname: "last_name", Uebername: "nickname", Ort: "town",
         Geburtstag: "birthday", Angaben: "additional_information",
         Telefon: "phone_number_work", Mobile: "phone_number_mobile", Tags: "tags"}
      end
      let(:update_behaviour) { "keep" }
      let(:dom) { Capybara::Node::Simple.new(response.body) }

      def cell(attr)
        index = dom.all("thead th").map { |th| th.text.strip }.index(Person.human_attribute_name(attr))
        dom.all("tbody tr td")[index].text.strip
      end

      def preview
        post :preview, params: required_params.merge(field_mappings: field_mappings,
          update_behaviour: update_behaviour)
      end

      before { sign_in(user) }

      context "with stored data" do
        let(:data) { generate_csv(headers, ["Top", "Leader", "Topi", "Bern", "", "", "", "", "csv-tag"]) }

        before do
          people(:top_leader).update!(birthday: "1.4.1970", tag_list: "secret-tag")
          people(:top_leader).phone_numbers.create!(number: "+41 79 123 45 67",
            category: contact_account_categories(:phone_number_person_work))
          people(:top_leader).phone_numbers.create!(number: "+41 79 765 43 21", public: false,
            category: contact_account_categories(:phone_number_person_mobile))
        end

        context "when the user has no show permission on the person" do
          let(:user) { Fabricate(Group::BottomLayer::LocalGuide.name, group: group).person }

          it "shows imported values and hides stored values" do
            preview

            expect(dom).to have_css("tbody tr i.fa-sync-alt")
            expect(cell(:nickname)).to eq "Topi"
            expect(cell(:town)).to eq "fehlende Berechtigung"
            expect(cell(:birthday)).to eq "fehlende Berechtigung"
            expect(cell(:additional_information)).to eq "fehlende Berechtigung"
            expect(cell(:tags)).to eq "csv-tag"
            expect(response.body).not_to include("Greattown", "01.04.1970", "bla bla", "79 123 45 67",
              "79 765 43 21", "secret-tag")
          end

          context "with override behaviour" do
            let(:update_behaviour) { "override" }

            it "shows imported values" do
              preview

              expect(cell(:town)).to eq "Bern"
              expect(cell(:birthday)).to be_blank
              expect(cell(:additional_information)).to be_blank
              expect(response.body).not_to include("Greattown", "01.04.1970", "bla bla", "79 123 45 67",
                "79 765 43 21", "secret-tag")
            end
          end

          it "marks person add request" do
            groups(:top_layer).update_column(:require_person_add_requests, true)

            preview

            expect(dom).to have_css("tbody tr i.fa-question")
          end
        end

        context "when the user has show permission on the person" do
          let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: group).person }

          it "shows stored values like person lists" do
            preview

            expect(cell(:town)).to eq "Greattown"
            expect(cell(:birthday)).to eq "fehlende Berechtigung"
            expect(cell(:additional_information)).to eq "fehlende Berechtigung"
            expect(cell(:tags)).to eq "csv-tag"
            expect(response.body).to include("79 123 45 67")
            expect(response.body).not_to include("01.04.1970", "bla bla", "79 765 43 21", "secret-tag")
          end
        end
      end

      context "with rows matching multiple people" do
        let(:user) { Fabricate(Group::BottomLayer::LocalGuide.name, group: group).person }
        let(:update_behaviour) { "override" }
        let(:other) do
          Fabricate(Group::TopGroup::Member.name, group: groups(:top_group),
            person: Fabricate(:person, email: "other@example.com")).person
        end
        let(:field_mappings) do
          {Vorname: "first_name", Nachname: "last_name", Email: "email", Telefon: "phone_number_work"}
        end
        let(:data) do
          generate_csv(%w[Vorname Nachname Email Telefon],
            ["Top", "Leader", other.email, "+41 11 111 11 11"],
            ["Top", "Leader", other.email, ""])
        end

        before do
          [people(:top_leader), other].each_with_index do |person, i|
            person.phone_numbers.create!(number: "+41 79 000 00 0#{i}",
              category: contact_account_categories(:phone_number_person_work))
          end
        end

        it "shows only the imported values of each row" do
          preview

          expect(dom).to have_css("tbody tr i.fa-exclamation-triangle", count: 2)
          expect(dom).to have_css("tbody td", text: "+41 11 111 11 11", count: 1)
          expect(response.body).not_to include("+41 79 000 00 00", "+41 79 000 00 01")
        end
      end

      context "when the user has show_full permission on the person" do
        let(:user) { Fabricate(Group::BottomLayer::LocalGuide.name, group: group).person }
        let(:data) { generate_csv(headers, ["Bottom", "Member", "", "", "", "", "", "", ""]) }

        it "shows stored values" do
          preview

          expect(cell(:town)).to eq "Greattown"
        end
      end
    end

    context "id mapping" do
      let(:data) { generate_csv(%w[ID Vorname], [Person.maximum(:id) + 1000, "foo"]) }
      let(:field_mappings) { {ID: "id", Vorname: "first_name"} }

      context "as admin" do
        it "renders the preview" do
          post :preview, params: required_params.merge(field_mappings: field_mappings)
          expect(flash[:notice]).to eq ["1 Person (Leader) wird neu importiert."]
          is_expected.to render_template(:preview)
        end
      end

      context "with rendered views" do
        render_views

        let(:hint) { "Die Duplikaterkennung ist deaktiviert" }

        it "hints that people are matched by id only" do
          post :preview, params: required_params.merge(field_mappings: field_mappings)
          expect(response.body).to include(hint)
        end

        it "shows no hint when id is not mapped" do
          post :preview, params: required_params.merge(field_mappings: {Vorname: "first_name"})
          expect(response.body).not_to include(hint)
        end
      end

      context "as non-admin" do
        let(:role_type) { "Group::BottomLayer::Member" }
        let(:group) { groups(:bottom_layer_one) }
        let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

        before { sign_in(user) }

        it "rejects the id mapping" do
          post :preview, params: required_params.merge(field_mappings: field_mappings)
          expect(flash[:alert]).to eq "Die Zuordnung einer Spalte auf die Personennummer erfordert Admin-Berechtigung."
          is_expected.to render_template(:define_mapping)
        end
      end
    end
  end

  describe "POST #create" do
    let(:data) { File.read(path(:utf8)) }
    let(:role_type) { Group::TopGroup::Leader }
    let(:mapping) { {Vorname: "first_name", Nachname: "last_name", Geburtsdatum: "birthday"} }
    let(:required_params) { {group_id: group.id, data: data, role_type: role_type.sti_name, field_mappings: mapping} }

    it "fails if role_type is missing" do
      expect do
        post :create, params: {group_id: group.id, data: data, field_mappings: {first_name: "first_name"}}
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders define_mapping if button is pressed" do
      post :create, params: required_params.merge(button: "back")
      is_expected.to render_template(:define_mapping)
    end

    it "populates flash and redirects to group role list" do
      expect { post :create, params: required_params }.to change(Person, :count).by(1)
      expect(flash[:notice]).to eq ["1 Person (Leader) wurde erfolgreich importiert."]
      expect(flash[:alert]).not_to be_present
      is_expected.to redirect_to group_people_path(group, filters: {role: {role_type_ids: [role_type.type_id]}},
        name: "Leader")
    end

    context "mapping misses attribute" do
      let(:mapping) { {email: :email, role: role_type.sti_name} }
      let(:data) { generate_csv(%w[name email], %w[foo foo@bar.net]) }

      it "imports first person and displays errors for second person" do
        expect { post :create, params: required_params }.to change(Person, :count).by(0)
        expect(flash[:alert]).to eq ["1 Person (Leader) wurde nicht importiert."]
        is_expected.to redirect_to group_people_path(group, filters: {role: {role_type_ids: [role_type.type_id]}},
          name: "Leader")
      end
    end

    context "trying to update email of user with superior permissions" do
      let(:role_type) { Group::BottomLayer::Member }
      let(:mapping) {
        {Nachname: "last_name",
         Geburtsdatum: "birthday",
         Email: "email"}
      }

      let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }
      let(:group) { groups(:bottom_layer_one) }

      let(:data) {
        generate_csv(%w[Nachname Email Geburtsdatum],
          [person.last_name, "abusive_email@example.com", person.birthday],
          ["new_user", "new_user@example.com", Time.zone.now])
      }

      let(:required_params) {
        {group_id: group.id,
         data: data,
         role_type: role_type.sti_name,
         field_mappings: mapping,
         update_behaviour: "override"}
      }

      before { sign_in(user) }

      it "does not update persisted user" do
        post :create, params: required_params

        expect(person.reload.email).to eq("top_leader@example.com")
        expect(Person.find_by(last_name: "new_user").email).to eq("new_user@example.com")
      end
    end

    context "invalid phone number value" do
      let(:mapping) { {Vorname: "first_name", Telefon: "phone_number_work", role: role_type.sti_name} }
      let(:data) { generate_csv(%w[Vorname Telefon], %w[foo]) }

      it "is ignored" do
        expect { post :create, params: required_params }.to change(Person, :count).by(1)
        expect(flash[:alert]).to be_blank
        is_expected.to redirect_to group_people_path(group, filters: {role: {role_type_ids: [role_type.type_id]}},
          name: "Leader")
      end
    end

    context "list" do
      let(:data) { File.read(path(:list)) }
      let(:last_person) { Person.last }

      context "mapping single attribute" do
        let(:mapping) { {first_name: "first_name"} }

        it "imports first name of all 4 people" do
          expect { post :create, params: required_params }.to change(Person, :count).by(4)
          expect(flash[:alert]).to be_blank
          expect(last_person.last_name).to be_blank
          expect(last_person.first_name).to be_present
        end
      end

      context "mapping all attributes" do
        let(:mapping) { headers_mapping(CSV.parse(data, headers: true)) }

        it "imports single person" do
          expect { post :create, params: required_params }.to change(Person, :count).by(1)
          expect(last_person.last_name).to be_present
          expect(last_person.phone_numbers.size).to eq(4)
          expect(last_person.social_accounts.size).to eq(3)
        end
      end

      context "with add request" do
        let(:role_type) { Group::BottomGroup::Member }
        let(:mapping) {
          {Vorname: "first_name", Nachname: "last_name", Geburtsdatum: "birthday", Email: "email", Ort: "town"}
        }

        let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }
        # use custom last_name to avoid duplicates, causing flaky specs
        let(:person) {
          Fabricate(Group::TopGroup::LocalSecretary.name, group: groups(:top_group),
            person: Fabricate(:person, last_name: "Zumimportieren")).person
        }
        let(:group) { groups(:bottom_group_one_one) }

        let(:data) { generate_csv(%w[Nachname Email Ort], [person.last_name, person.email, "Wabern"]) }

        before { sign_in(user) }
        before { groups(:top_layer).update_column(:require_person_add_requests, true) }

        it "creates request" do
          person # create
          post :create, params: required_params.merge(update_behaviour: "override")
          is_expected.to redirect_to group_people_path(group, filters: {role: {role_type_ids: [role_type.type_id]}},
            name: "Member")

          expect(person.reload.roles.count).to eq(1)
          expect(person.town).not_to eq("Wabern")
          request = person.add_requests.first
          expect(request.body_id).to eq(group.id)
          expect(request.role_type).to eq(role_type.sti_name)
          expect(flash[:alert].join).to match(/Zugriffsanfrage .*erhalten/)
        end

        it "creates role if person already visible" do
          person # create
          Fabricate(Group::TopGroup::Member.name, group: groups(:top_group), person: user)

          post :create, params: required_params.merge(update_behaviour: "override")
          is_expected.to redirect_to group_people_path(group, filters: {role: {role_type_ids: [role_type.type_id]}},
            name: "Member")

          expect(person.reload.roles.count).to eq(2)
          expect(person.town).to eq("Wabern")
          role = person.roles.last
          expect(role.group_id).to eq(group.id)
          expect(flash[:notice].join).to eq("1 Person (Member) wurde erfolgreich aktualisiert.")
        end

        it "informs about existing request" do
          Person::AddRequest::Group.create!(
            person: person,
            requester: Fabricate(:person),
            body: group,
            role_type: Group::BottomGroup::Leader.sti_name
          )

          post :create, params: required_params

          is_expected.to redirect_to group_people_path(group, filters: {role: {role_type_ids: [role_type.type_id]}},
            name: "Member")
          expect(person.reload.roles.count).to eq(1)
          expect(person.add_requests.count).to eq(1)
          expect(flash[:alert].join).to match(/Zugriffsanfrage .*erhalten/)
        end
      end
    end

    context "id mapping" do
      let(:new_id) { Person.maximum(:id) + 1000 }
      let(:data) { generate_csv(%w[ID Vorname], [new_id, "foo"]) }
      let(:mapping) { {ID: "id", Vorname: "first_name"} }

      context "as admin" do
        it "imports person with the given id" do
          expect { post :create, params: required_params }.to change(Person, :count).by(1)
          expect(Person.find(new_id).first_name).to eq "foo"
        end
      end

      context "as non-admin" do
        let(:role_type) { Group::BottomLayer::Member }
        let(:group) { groups(:bottom_layer_one) }
        let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

        before { sign_in(user) }

        it "rejects the id mapping" do
          expect { post :create, params: required_params }.not_to change(Person, :count)
          expect(flash[:alert]).to eq "Die Zuordnung einer Spalte auf die Personennummer erfordert Admin-Berechtigung."
          is_expected.to render_template(:define_mapping)
        end
      end
    end

    context "doublette handling" do
      context "multiple updates to single person" do
        let(:mapping) { {vorname: :first_name, email: :email, nickname: :nickname} }
        let(:data) { generate_csv(%w[vorname email nickname], %w[foo foo@bar.net foobar], %w[bar bar@bar.net barfoo]) }

        before do
          @person = Fabricate(:person, first_name: "bar", email: "foo@bar.net", nickname: "")
        end

        it "last update wins" do
          expect do
            expect do
              post :create, params: required_params
            end.to change { Role.count }.by(1)
          end.not_to change { Person.count }

          expect(flash[:notice]).to eq ["1 Person (Leader) wurde erfolgreich aktualisiert."]
          expect(@person.reload.nickname).to eq "foobar"
        end
      end

      context "csv data matches multiple people" do
        let(:mapping) { {vorname: :first_name, email: :email, role: role_type.sti_name} }
        let(:data) { generate_csv(%w[vorname email], %w[foo foo@bar.net]) }

        it "reports error if multiple candidates for doublettes are found" do
          Fabricate(:person, first_name: "bar", email: "foo@bar.net")
          Fabricate(:person, first_name: "foo", email: "bar@bar.net")
          post :create, params: required_params
          expect(flash[:alert]).to eq ["1 Person (Leader) wurde nicht importiert."]
        end
      end
    end
  end
end
