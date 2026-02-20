# frozen_string_literal: true

#  Copyright (c) 2014 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaperTrail::VersionDecorator, :draper_with_helpers, versioning: true do
  include Rails.application.routes.url_helpers

  let(:person) { people(:top_leader) }
  let(:version) { PaperTrail::Version.where(main_id: person.id).order(:created_at, :id).last }
  let(:decorator) { PaperTrail::VersionDecorator.new(version) }

  before { PaperTrail.request.whodunnit = nil }

  context "#header" do
    subject { decorator.header }

    context "without current user" do
      before { update }

      it { is_expected.to match(/^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr$/) }
    end

    context "with current user" do
      before do
        PaperTrail.request.whodunnit = person.id.to_s
        update
      end

      it do
        is_expected.to match(
          /^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr<br \/>geändert durch <a href=".+">#{person}<\/a>$/
        )
      end
    end

    context "with deleted current user" do
      let(:user) { Fabricate(:person) }

      before do
        PaperTrail.request.whodunnit = user.id.to_s
        update
        user.destroy!
      end

      it do
        is_expected.to match(
          /^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr<br \/>geändert durch inzwischen gelöschte Person #{user.id}$/
        )
      end
    end
  end

  context "#author" do
    subject { decorator.author }

    context "without current user" do
      before { update }

      it { is_expected.to be_nil }
    end

    context "with current user" do
      before do
        PaperTrail.request.whodunnit = person.id.to_s
        update
      end

      context "and permission to link" do
        it do
          expect(decorator.h).to receive(:can?).with(:show, person).and_return(true)
          is_expected.to match(/^<a href=".+">#{person}<\/a>$/)
        end
      end

      context "and no permission to link" do
        it do
          expect(decorator.h).to receive(:can?).with(:show, person).and_return(false)
          is_expected.to eq(person.to_s)
        end
      end
    end

    context "with service token" do
      let(:service_token) { service_tokens(:permitted_top_layer_token) }

      before do
        PaperTrail.request.whodunnit = service_token.id.to_s
        PaperTrail.request.controller_info = {whodunnit_type: ServiceToken.sti_name}
        update
      end

      context "and permission to link" do
        it do
          expect(decorator.h).to receive(:can?).with(:show, service_token).and_return(true)
          is_expected.to match(/^<a href=".+">API-Key: Permitted<\/a>$/)
        end
      end

      context "and no permission to link" do
        it do
          expect(decorator.h).to receive(:can?).with(:show, service_token).and_return(false)
          is_expected.to eq("API-Key: Permitted")
        end
      end
    end
  end

  context "#changes" do
    subject { decorator.changes }

    context "with attribute changes" do
      before { update }

      it { is_expected.to match(/<div>Ort wurde/) }
      it { is_expected.to match(/<div>PLZ wurde/) }
    end

    context "with association changes" do
      context "social account" do
        before { Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar") }

        it { is_expected.to match(/<div>Social Media/) }
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
    end
  end

  context "#attribute_change" do
    before { update }

    it "contains from and to attributes" do
      string = decorator.attribute_change(:first_name, "Hans", "Fritz")
      expect(string).to be_html_safe
      expect(string).to eq("Vorname wurde von <i>Hans</i> auf <i>Fritz</i> geändert.")
    end

    it "contains only from attribute" do
      string = decorator.attribute_change(:first_name, "Hans", " ")
      expect(string).to be_html_safe
      expect(string).to eq("Vorname <i>Hans</i> wurde gelöscht.")
    end

    it "contains only to attribute" do
      string = decorator.attribute_change(:first_name, nil, "Fritz")
      expect(string).to be_html_safe
      expect(string).to eq("Vorname wurde auf <i>Fritz</i> gesetzt.")
    end

    it "is empty without from and to " do
      string = decorator.attribute_change(:first_name, nil, "")
      expect(string).to be_blank
    end

    it "escapes html" do
      string = decorator.attribute_change(:first_name, nil, "<b>Fritz</b>")
      expect(string).to eq("Vorname wurde auf <i>&lt;b&gt;Fritz&lt;/b&gt;</i> gesetzt.")
    end

    it "formats according to column info" do
      now = Time.zone.local(2014, 6, 21, 18)
      string = decorator.attribute_change(:updated_at, nil, now)
      expect(string).to eq "Geändert wurde auf <i>21.06.2014 18:00</i> gesetzt."
    end
  end

  context "#association_change" do
    subject { decorator.association_change }

    it "builds create text" do
      Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")

      is_expected.to eq("Social Media Adresse <i>Bar (Foo)</i> wurde hinzugefügt.")
    end

    it "builds create text for later deleted association" do
      account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
      SocialAccount.where(id: account.id).delete_all

      is_expected.to eq("Social Media Adresse <i>Bar (Foo)</i> wurde hinzugefügt.")
    end

    it "sanitizes html" do
      Fabricate(:social_account, contactable: person, label: "Foo",
        name: '<script>alert("test")</script>')

      is_expected.to eq('Social Media Adresse <i>alert("test") (Foo)</i> wurde hinzugefügt.')
    end

    it "builds update text" do
      account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
      account.update!(name: "Boo")

      is_expected.to eq("Social Media Adresse <i>Bar (Foo)</i> wurde aktualisiert: " \
                        "Name wurde von <i>Bar</i> auf <i>Boo</i> geändert.")
    end

    it "builds destroy text" do
      account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
      account.destroy!

      is_expected.to eq("Social Media Adresse <i>Bar (Foo)</i> wurde gelöscht.")
    end
  end

  context "association_change for people_manager" do
    subject { decorator.association_change }

    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }

    context "as manager" do
      it "builds create text" do
        PeopleManager.create(manager: top_leader, managed: bottom_member)

        is_expected.to eq("<i>Bottom Member</i> wurde als Kind hinzugefügt.")
      end

      it "builds create text for later deleted people manager" do
        pm = PeopleManager.create(manager: top_leader, managed: bottom_member)
        PeopleManager.where(id: pm.id).delete_all

        is_expected.to eq("<i>Bottom Member</i> wurde als Kind hinzugefügt.")
      end

      it "builds create text for later deleted managed" do
        PeopleManager.create(manager: top_leader, managed: bottom_member)
        Person.where(id: bottom_member.id).delete_all

        is_expected.to eq("<i>(Gelöschte Person)</i> wurde als Kind hinzugefügt.")
      end

      it "builds destroy text" do
        pm = PeopleManager.create(manager: top_leader, managed: bottom_member)
        pm.destroy!

        is_expected.to eq("<i>Bottom Member</i> wurde als Kind entfernt.")
      end

      it "works with deleted user" do
        pm = PeopleManager.create(manager: top_leader, managed: bottom_member)
        pm.destroy!
        bottom_member.destroy!

        is_expected.to eq("<i>(Gelöschte Person)</i> wurde als Kind entfernt.")
      end
    end

    context "as managed" do
      it "builds create text" do
        PeopleManager.create(managed: top_leader, manager: bottom_member)

        is_expected.to eq("<i>Bottom Member</i> wurde als Verwalter*in hinzugefügt.")
      end

      it "builds create text for later deleted people manager" do
        pm = PeopleManager.create(managed: top_leader, manager: bottom_member)
        PeopleManager.where(id: pm.id).delete_all

        is_expected.to eq("<i>Bottom Member</i> wurde als Verwalter*in hinzugefügt.")
      end

      it "builds create text for later deleted manager" do
        PeopleManager.create(managed: top_leader, manager: bottom_member)
        Person.where(id: bottom_member.id).delete_all

        is_expected.to eq("<i>(Gelöschte Person)</i> wurde als Verwalter*in hinzugefügt.")
      end

      it "builds destroy text" do
        pm = PeopleManager.create(managed: top_leader, manager: bottom_member)
        pm.destroy!

        is_expected.to eq("<i>Bottom Member</i> wurde als Verwalter*in entfernt.")
      end

      it "works with deleted user" do
        pm = PeopleManager.create(managed: top_leader, manager: bottom_member)
        pm.destroy!
        bottom_member.destroy!

        is_expected.to eq("<i>(Gelöschte Person)</i> wurde als Verwalter*in entfernt.")
      end
    end
  end

  def update
    person.update!(town: "Bern", zip_code: "3007")
  end
end
