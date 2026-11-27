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
    expect(emails).to match_array([
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
    expect(emails).to match_array([
      "hitobito@puzzle.ch",
      "top_leader@example.com"
    ])
  end

  it "it uses only additional_email if label matches" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "foo")
    expect(emails([top_leader], %w[foo])).to match_array([
      e1.email
    ])
  end

  it "it uses additional_email and main address if matches" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "foo")
    expect(emails([top_leader], %W[foo #{MailingList::DEFAULT_LABEL}])).to match_array([
      e1.email,
      top_leader.email
    ])
  end

  it "it uses all matching additional_emails" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "foo")
    e2 = Fabricate(:additional_email, contactable: top_leader, label: "bar")
    expect(emails([top_leader], %w[foo bar])).to match_array([
      e1.email,
      e2.email
    ])
  end

  it "it ignores case when mathing labels" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: "FOO")
    expect(emails([top_leader], %w[foo])).to match_array([
      e1.email
    ])
  end

  it "it leading and trailing whitespaces case when mathing labels" do
    e1 = Fabricate(:additional_email, contactable: top_leader, label: " FOO ")
    expect(emails([top_leader], %w[foo])).to match_array([
      e1.email
    ])
  end

  it "matches additional email by category key" do
    e1 = Fabricate(:additional_email, contactable: top_leader,
      category: contact_account_categories(:additional_email_person_work), label: nil)
    expect(emails([top_leader], %w[work])).to match_array([e1.email])
  end

  it "does not match additional email by translated category name" do
    Fabricate(:additional_email, contactable: top_leader,
      category: contact_account_categories(:additional_email_person_work), label: nil,
      mailings: false)
    expect(emails([top_leader], %w[arbeit])).to match_array([top_leader.email])
  end

  it "matches additional email by label when it does not match a category key" do
    e1 = Fabricate(:additional_email, contactable: top_leader,
      category: contact_account_categories(:additional_email_person_work), label: "büro")
    expect(emails([top_leader], %w[büro])).to match_array([e1.email])
  end

  it "matches other category by key like any other category" do
    e1 = Fabricate(:additional_email, contactable: top_leader,
      category: contact_account_categories(:additional_email_person_other),
      label: "foo", mailings: false)
    expect(emails([top_leader], %w[other])).to match_array([e1.email])
  end

  it "does not match other category by translated category name" do
    Fabricate(:additional_email, contactable: top_leader,
      category: contact_account_categories(:additional_email_person_other),
      label: "foo", mailings: false)
    expect(emails([top_leader], %w[andere])).to match_array([top_leader.email])
  end

  it "falls back to default behviour of no label matches" do
    e1 = Fabricate(:additional_email, contactable: top_leader, mailings: true)
    Fabricate(:additional_email, contactable: top_leader, label: "buz", mailings: false)
    expect(emails([top_leader], %w[foo bar])).to match_array([
      "top_leader@example.com",
      e1.email
    ])
  end

  it "works for new records" do
    person = Fabricate(:person)
    e1 = Fabricate(:additional_email, contactable: person, mailings: true)
    Fabricate(:additional_email, contactable: bottom_member, mailings: false)
    expect(emails(person)).to match_array([
      person.email,
      e1.email
    ])
  end

  def emails(people = Person.all, labels = [])
    described_class.new(people, labels).emails
  end

  def person_emails(people, labels = [])
    described_class.new(people, labels).person_emails
  end

  it "lists person emails with the id of their person" do
    e1 = Fabricate(:additional_email, contactable: top_leader, mailings: true)
    expect(person_emails([top_leader, bottom_member])).to match_array([
      {person_id: top_leader.id, email: top_leader.email},
      {person_id: top_leader.id, email: e1.email},
      {person_id: bottom_member.id, email: bottom_member.email}
    ])
  end

  it "does not list managers when people managers feature is disabled" do
    allow(FeatureGate).to receive(:enabled?).and_call_original
    allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return false
    bottom_member.managers = [top_leader]

    expect(person_emails([bottom_member])).to eq([
      {person_id: bottom_member.id, email: bottom_member.email}
    ])
  end

  context "with people_managers feature" do
    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }
    let(:manager) {
      Fabricate(:person, first_name: "People Manager", email: "people_manager@example.com",
        primary_group: groups(:bottom_group_two_one))
    }
    let(:managed) {
      Fabricate(:person, first_name: "People Managed", email: "people_managed@example.com",
        primary_group: groups(:bottom_group_two_one))
    }

    before do
      managed.update! managers: [manager]

      allow(FeatureGate).to receive(:enabled?).and_call_original
      allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return true
    end

    it "lists manager emails with the id of the manager" do
      expect(person_emails([managed])).to match_array([
        {person_id: managed.id, email: managed.email},
        {person_id: manager.id, email: manager.email}
      ])
    end

    context "emails" do
      it "contains main and additional managers mailing emails" do
        e1 = Fabricate(:additional_email, contactable: manager, mailings: true)
        e2 = Fabricate(:additional_email, contactable: top_leader, mailings: true)

        Fabricate(:additional_email, contactable: manager, mailings: false)
        Fabricate(:additional_email, contactable: managed, mailings: false)
        expect(emails([managed, top_leader])).to match_array([
          managed.email,
          "top_leader@example.com",
          manager.email,
          e1.email,
          e2.email
        ])
      end

      it "does not contain blank manager emails" do
        manager.update!(email: " ")

        expect(emails(managed)).to match_array([
          managed.email
        ])
      end

      it "it uses only manager additional_email if label matches" do
        e1 = Fabricate(:additional_email, contactable: managed, label: "foo")
        e2 = Fabricate(:additional_email, contactable: manager, label: "foo")
        Fabricate(:additional_email, contactable: manager, label: "bar")
        expect(emails(managed, %w[foo])).to match_array([
          e1.email,
          e2.email
        ])
      end

      it "it uses manager additional_email and main address if matches" do
        e1 = Fabricate(:additional_email, contactable: managed, label: "foo")
        e2 = Fabricate(:additional_email, contactable: manager, label: "foo")
        expect(emails(managed, %W[foo #{MailingList::DEFAULT_LABEL}])).to match_array([
          e1.email,
          e2.email,
          managed.email,
          manager.email
        ])
      end

      it "for new person returns only the person" do
        new_manager = Fabricate.build(:person)
        new_person = Fabricate.build(:person, managers: [new_manager])
        expect(emails(new_person)).to match_array([
          new_person.email,
          new_manager.email
        ])
      end

      it "contains only manager emails when managed has no email" do
        managed.update!(email: nil)

        expect(emails(managed)).to match_array([
          manager.email
        ])
      end
    end
  end
end
