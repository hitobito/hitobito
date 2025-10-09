#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailRelay::AddressList do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  it "contains main and additional mailing emails" do
    e1 = Fabricate(:additional_email, contactable: top_leader, mailings: true)
    Fabricate(:additional_email, contactable: bottom_member, mailings: false)
    expect(entries).to match_array([
      "bottom_member@example.com",
      "hitobito@puzzle.ch",
      "top_leader@example.com",
      e1.email
    ])
  end

  it "does not contain blank emails" do
    btm = people(:bottom_member)
    btm.email = " "
    btm.save!
    expect(entries).to match_array([
      "hitobito@puzzle.ch",
      "top_leader@example.com"
    ])
  end

  it "it uses only additional_email if label matches" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "foo")
    expect(entries([top_leader], %w[foo])).to match_array([
      e1.email
    ])
  end

  it "it uses additional_email and main address if matches" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "foo")
    expect(entries([top_leader], %W[foo #{MailingList::DEFAULT_LABEL}])).to match_array([
      e1.email,
      top_leader.email
    ])
  end

  it "it uses all matching additional_emails" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "foo")
    e2 = Fabricate(:additional_email, contactable: top_leader, label: "bar")
    expect(entries([top_leader], %w[foo bar])).to match_array([
      e1.email,
      e2.email
    ])
  end

  it "it ignores case when mathing labels" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "FOO")
    expect(entries([top_leader], %w[foo])).to match_array([
      e1.email
    ])
  end

  it "it leading and trailing whitespaces case when mathing labels" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: " FOO ")
    expect(entries([top_leader], %w[foo])).to match_array([
      e1.email
    ])
  end

  it "falls back to default behviour of no label matches" do
    e1 = Fabricate(:additional_email, contactable: top_leader, mailings: true)
    Fabricate(:additional_email, contactable: top_leader, label: "buz", mailings: false)
    expect(entries([top_leader], %w[foo bar])).to match_array([
      "top_leader@example.com",
      e1.email
    ])
  end

  it "works for new records" do
    person = Fabricate(:person)
    e1 = Fabricate(:additional_email, contactable: person, mailings: true)
    Fabricate(:additional_email, contactable: bottom_member, mailings: false)
    expect(entries(person)).to match_array([
      person.email,
      e1.email
    ])
  end

  def entries(people = Person.all, labels = [])
    described_class.new(people, labels).entries
  end

  context "with people_managers feature" do
    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }
    let(:manager) { Fabricate(:person, first_name: "People Manager", email: "people_manager@example.com", primary_group: groups(:bottom_group_two_one)) }
    let(:managed) { Fabricate(:person, first_name: "People Managed", email: "people_managed@example.com", primary_group: groups(:bottom_group_two_one)) }

    before do
      managed.update! managers: [manager]

      allow(FeatureGate).to receive(:enabled?).and_call_original
      allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return true
    end

    context "entries" do
      it "contains main and additional managers mailing emails" do
        e1 = Fabricate(:additional_email, contactable: manager, mailings: true)
        e2 = Fabricate(:additional_email, contactable: top_leader, mailings: true)

        Fabricate(:additional_email, contactable: manager, mailings: false)
        Fabricate(:additional_email, contactable: managed, mailings: false)
        expect(entries([managed, top_leader])).to match_array([
          managed.email,
          "top_leader@example.com",
          manager.email,
          e1.email,
          e2.email
        ])
      end

      it "does not contain blank manager emails" do
        manager.update!(email: " ")

        expect(entries(managed)).to match_array([
          managed.email
        ])
      end

      it "it uses only manager additional_email if label matches" do
        e1 = Fabricate(:additional_email, contactable: managed, label: "foo")
        e2 = Fabricate(:additional_email, contactable: manager, label: "foo")
        Fabricate(:additional_email, contactable: manager, label: "bar")
        expect(entries(managed, %w[foo])).to match_array([
          e1.email,
          e2.email
        ])
      end

      it "it uses manager additional_email and main address if matches" do
        e1 = Fabricate(:additional_email, contactable: managed, label: "foo")
        e2 = Fabricate(:additional_email, contactable: manager, label: "foo")
        expect(entries(managed, %W[foo #{MailingList::DEFAULT_LABEL}])).to match_array([
          e1.email,
          e2.email,
          managed.email,
          manager.email
        ])
      end

      it "for new person returns only the person" do
        new_manager = Fabricate.build(:person)
        new_person = Fabricate.build(:person, managers: [new_manager])
        expect(entries(new_person)).to match_array([
          new_person.email,
          new_manager.email
        ])
      end

      it "contains only manager emails when managed has no email" do
        managed.update!(email: nil)

        expect(entries(managed)).to match_array([
          manager.email
        ])
      end
    end

    def entries(people = Person.all, labels = [])
      described_class.new(people, labels).entries
    end
  end
end
