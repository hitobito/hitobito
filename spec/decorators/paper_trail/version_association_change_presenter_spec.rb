#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaperTrail::VersionAssociationChangePresenter, :draper_with_helpers, versioning: true do
  let(:person) { people(:top_leader) }
  let(:version) { PaperTrail::Version.where(main_id: person.id).order(:created_at, :id).last }
  let(:view_context) { ActionController::Base.new.view_context }
  let(:presenter) { PaperTrail::VersionAssociationChangePresenter.new(version, view_context) }

  before do
    PaperTrail.request.whodunnit = nil
    view_context.extend(FormatHelper)
  end

  subject { presenter.render }

  it "builds create text" do
    Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")

    is_expected.to eq("<div>Social Media Adresse <i>Bar (Foo)</i> wurde hinzugefügt.</div>")
  end

  it "builds create text for later deleted association" do
    account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
    SocialAccount.where(id: account.id).delete_all

    is_expected.to eq("<div>Social Media Adresse <i>Bar (Foo)</i> wurde hinzugefügt.</div>")
  end

  it "sanitizes html" do
    Fabricate(:social_account, contactable: person, label: "Foo",
      name: '<script>alert("test")</script>')

    is_expected.to eq('<div>Social Media Adresse <i>alert("test") (Foo)</i> wurde hinzugefügt.</div>')
  end

  it "builds update text" do
    account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
    account.update!(name: "Boo")

    is_expected.to eq("<div>Social Media Adresse <i>Boo (Foo)</i> wurde aktualisiert: " \
                      "Name wurde von <i>Bar</i> auf <i>Boo</i> geändert.</div>")
  end

  it "builds update text for belongs_to attribute" do
    person.update!(primary_group: groups(:bottom_layer_one))

    is_expected.to eq("<div>Person <i>Top Leader</i> wurde aktualisiert: Hauptgruppe " \
    "wurde von <i>TopGroup</i> auf <i>Bottom One</i> geändert.</div>")
  end

  it "builds destroy text" do
    account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
    account.destroy!

    is_expected.to eq("<div>Social Media Adresse <i>Bar (Foo)</i> wurde gelöscht.</div>")
  end

  it "builds removed text" do
    # Create a custom removed version for a HABTM association
    PaperTrail::Version.create!(main: person,
      item: groups(:top_layer),
      event: :removed,
      object: groups(:top_layer),
      object_changes: {}.to_yaml)

    is_expected.to eq("<div>Gruppe <i>Top</i> wurde entfernt.</div>")
  end

  context "for role type that does not exist anymore" do
    it "builds update text" do
      PaperTrail::Version.create!(
        item_type: "Role", item_id: Role.maximum(:id).succ, # id to role that does not exist
        object: {"type" => "Group::SektionsMitglieder::NonExistentRoleType"}.to_yaml,
        object_changes: {"end_on" => [Date.new(2026, 3, 1), Date.new(2026, 5, 1)]}.to_yaml,
        main: person, event: :update
      )

      is_expected.to eq("<div>Rolle <i>Group::SektionsMitglieder::NonExistentRoleType</i> wurde aktualisiert: " \
                        "Bis wurde von <i>01.03.2026</i> auf <i>01.05.2026</i> geändert.</div>")
    end

    it "builds create text" do
      PaperTrail::Version.create!(
        item_type: "Role", item_id: Role.maximum(:id).succ, # id to role that does not exist
        object: nil,
        object_changes: {"type" => [nil, "Group::SacCasKurskader::NonExistentRoleType"]}.to_yaml,
        main: person, event: :create
      )

      is_expected.to eq("<div>Rolle <i>Group::SacCasKurskader::NonExistentRoleType</i> wurde hinzugefügt.</div>")
    end

    it "builds removed text" do
      PaperTrail::Version.create!(
        item_type: "Role", item_id: Role.maximum(:id).succ, # id to role that does not exist
        object: nil,
        object_changes: {"type" => [nil, "Group::SacCasKurskader::NonExistentRoleType"]}.to_yaml,
        main: person, event: :removed
      )

      is_expected.to eq("<div>Rolle <i>Group::SacCasKurskader::NonExistentRoleType</i> wurde entfernt.</div>")
    end
  end

  context "mailing list" do
    let(:list) { mailing_lists(:leaders) }

    it "new add request" do
      Person::AddRequest::MailingList.create!(
        person: person, body: list, requester: people(:top_leader)
      )
      expect(subject).to eq(
        "<div>Zugriffsanfrage für <i>Abo Leaders in Top Layer Top</i> wurde gestellt.</div>"
      )
    end

    it "destroyed add request" do
      Person::AddRequest::MailingList.create!(
        person: person, body: list, requester: people(:top_leader)
      ).destroy!
      expect(subject).to eq(
        "<div>Zugriffsanfrage für <i>Abo Leaders in Top Layer Top</i> wurde beantwortet.</div>"
      )
    end

    it "destroyed mailing list still shows label" do
      Person::AddRequest::MailingList.create!(
        person: person, body: list, requester: people(:top_leader)
      )
      list.destroy
      expect(subject).to eq "<div>Zugriffsanfrage für <i>Abo Leaders in Top Layer Top</i> wurde beantwortet.</div>"
    end
  end

  context "association_change for people_manager" do
    subject { presenter.render }

    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }

    context "as manager" do
      it "builds create text" do
        PeopleManager.create(manager: top_leader, managed: bottom_member)

        is_expected.to eq("<div><i>Bottom Member</i> wurde als Kind hinzugefügt.</div>")
      end

      it "builds create text for later deleted people manager" do
        pm = PeopleManager.create(manager: top_leader, managed: bottom_member)
        PeopleManager.where(id: pm.id).delete_all

        is_expected.to eq("<div><i>Bottom Member</i> wurde als Kind hinzugefügt.</div>")
      end

      it "builds create text for later deleted managed" do
        PeopleManager.create(manager: top_leader, managed: bottom_member)
        Person.where(id: bottom_member.id).delete_all

        is_expected.to eq("<div><i>(Gelöschte Person)</i> wurde als Kind hinzugefügt.</div>")
      end

      it "builds destroy text" do
        pm = PeopleManager.create(manager: top_leader, managed: bottom_member)
        pm.destroy!

        is_expected.to eq("<div><i>Bottom Member</i> wurde als Kind entfernt.</div>")
      end

      it "works with deleted user" do
        pm = PeopleManager.create(manager: top_leader, managed: bottom_member)
        pm.destroy!
        bottom_member.destroy!

        is_expected.to eq("<div><i>(Gelöschte Person)</i> wurde als Kind entfernt.</div>")
      end
    end

    context "as managed" do
      it "builds create text" do
        PeopleManager.create(managed: top_leader, manager: bottom_member)

        is_expected.to eq("<div><i>Bottom Member</i> wurde als Verwalter*in hinzugefügt.</div>")
      end

      it "builds create text for later deleted people manager" do
        pm = PeopleManager.create(managed: top_leader, manager: bottom_member)
        PeopleManager.where(id: pm.id).delete_all

        is_expected.to eq("<div><i>Bottom Member</i> wurde als Verwalter*in hinzugefügt.</div>")
      end

      it "builds create text for later deleted manager" do
        PeopleManager.create(managed: top_leader, manager: bottom_member)
        Person.where(id: bottom_member.id).delete_all

        is_expected.to eq("<div><i>(Gelöschte Person)</i> wurde als Verwalter*in hinzugefügt.</div>")
      end

      it "builds destroy text" do
        pm = PeopleManager.create(managed: top_leader, manager: bottom_member)
        pm.destroy!

        is_expected.to eq("<div><i>Bottom Member</i> wurde als Verwalter*in entfernt.</div>")
      end

      it "works with deleted user" do
        pm = PeopleManager.create(managed: top_leader, manager: bottom_member)
        pm.destroy!
        bottom_member.destroy!

        is_expected.to eq("<div><i>(Gelöschte Person)</i> wurde als Verwalter*in entfernt.</div>")
      end
    end
  end

  context "without item_label" do
    before do
      allow_any_instance_of(PaperTrail::Version).to receive(:item_label).and_return(nil)
    end

    it "displays unbekannt for version with label from untracked association" do
      Person::AddRequest::MailingList.create!(
        person: person, body: mailing_lists(:leaders), requester: people(:top_leader)
      )
      mailing_lists(:leaders).destroy
      expect(subject).to eq "<div>Zugriffsanfrage für <i>unbekannt</i> wurde beantwortet.</div>"
    end
  end

  context "with ancient attributes that got removed in the meantime" do
    let(:event) { events(:top_course) }
    let(:version) { PaperTrail::Version.where(main: event).order(:created_at, :id).last }

    it "reifies the remaining attributes for create" do
      PaperTrail::Version.create!(
        item_type: "Event::Question",
        item_id: 1001,
        object: {"type" => "Event::Question::Default"}.to_yaml,
        object_changes: {
          "question_de" => [nil, "Ich habe folgendes ÖV Abo"],
          "disclosure" => [nil, "hidden"],
          "type" => [nil, "Event::Question::Default"],
          "derived_from_question_id" => [nil, 3],
          "event_type" => [nil, "Event::Course"]
        }.to_yaml,
        main: event,
        event: :create
      )
      expect(subject).to eq("<div>Anmeldeangabe <i></i> wurde hinzugefügt.</div>")
    end

    it "reifies the remaining attributes for update" do
      PaperTrail::Version.create!(
        item_type: "Event::Question",
        item_id: 1001,
        object: {"type" => "Event::Question::Default"}.to_yaml,
        object_changes: {
          "question_de" => ["Ich habe folgendes Abo", "Ich habe folgendes ÖV Abo"],
          "disclosure" => ["required", "optional"]
        }.to_yaml,
        main: event,
        event: :update
      )
      expect(subject).to eq("<div>Anmeldeangabe <i></i> wurde aktualisiert: " \
       "Frage (DE) wurde von <i>Ich habe folgendes Abo</i> auf <i>Ich habe folgendes ÖV Abo</i> geändert., " \
       "Disclosure wurde von <i>required</i> auf <i>optional</i> geändert.</div>")
    end
  end

  def update
    person.update!(town: "Bern", zip_code: "3007")
  end
end
