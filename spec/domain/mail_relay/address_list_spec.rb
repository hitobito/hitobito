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
      "pushkar@vibha.org",
      "top_leader@example.com",
      e1.email
    ])
  end

  it "does not contain blank emails" do
    btm = people(:bottom_member)
    btm.email = " "
    btm.save!
    expect(entries).to match_array([
      "pushkar@vibha.org",
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
end
