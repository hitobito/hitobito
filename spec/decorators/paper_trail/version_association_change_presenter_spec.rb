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

    is_expected.to eq("<div>Social Media Adresse <i>Bar (Foo)</i> wurde aktualisiert: " \
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

    it "destroyed mailing list" do
      Person::AddRequest::MailingList.create!(
        person: person, body: list, requester: people(:top_leader)
      )
      list.destroy
      expect(subject).to eq "<div>Zugriffsanfrage für <i>unbekannt</i> wurde beantwortet.</div>"
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

  def update
    person.update!(town: "Bern", zip_code: "3007")
  end
end
