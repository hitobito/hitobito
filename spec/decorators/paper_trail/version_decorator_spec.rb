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

      it { is_expected.to match(/^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr<br \/>von <a href=".+">#{person}<\/a>$/) }
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
  end

  context "#changes" do
    subject { decorator.changes }

    context "with attribute changes" do
      before { update }

      it { is_expected.to match(/<div>Ort wurde/) }
      it { is_expected.to match(/<div>PLZ wurde/) }
      it { is_expected.to match(/<div>Haupt-E-Mail wurde/) }
    end

    context "with association changes" do
      context "social account" do
        before { Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar") }

        it { is_expected.to match(/<div>Social Media/) }
      end

      context "mailing list" do
        let(:list) { mailing_lists(:leaders) }

        it "new add request" do
          Person::AddRequest::MailingList.create!(person: person, body: list, requester: people(:top_leader))
          expect(subject).to eq "<div>Zugriffsanfrage für <i>Abo Leaders in Top Layer Top</i> wurde gestellt.</div>"
        end

        it "destroyed add request" do
          Person::AddRequest::MailingList.create!(person: person, body: list, requester: people(:top_leader)).destroy!
          expect(subject).to eq "<div>Zugriffsanfrage für <i>Abo Leaders in Top Layer Top</i> wurde beantwortet.</div>"
        end

        it "destroyed mailing list" do
          Person::AddRequest::MailingList.create!(person: person, body: list, requester: people(:top_leader))
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

    it "sanitizes html" do
      Fabricate(:social_account, contactable: person, label: "Foo", name: '<script>alert("test")</script>')

      is_expected.to eq('Social Media Adresse <i>alert("test") (Foo)</i> wurde hinzugefügt.')
    end

    it "builds update text" do
      account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
      account.update!(name: "Boo")

      is_expected.to eq("Social Media Adresse <i>Bar (Foo)</i> wurde aktualisiert: Name wurde von <i>Bar</i> auf <i>Boo</i> geändert.")
    end

    it "builds destroy text" do
      account = Fabricate(:social_account, contactable: person, label: "Foo", name: "Bar")
      account.destroy!

      is_expected.to eq("Social Media Adresse <i>Bar (Foo)</i> wurde gelöscht.")
    end

    it "builds destroy text for non existing Role class" do
      role = Fabricate(Group::BottomLayer::Leader.name.to_s, label: "foo", person: person, group: groups(:bottom_layer_one))
      role.destroy!
      hide_const("Group::BottomLayer::Leader")
      is_expected.to eq("Rolle <i>Group::BottomLayer::Leader</i> wurde gelöscht.")
    end
  end

  def update_attributes
    person.update!(town: "Bern", zip_code: "3007", email: "new@hito.example.com")
  end
end
