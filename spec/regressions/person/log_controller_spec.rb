#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::LogController, type: :controller do
  render_views

  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:test_entry) { top_leader }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(top_leader) }

  describe "GET index", versioning: true do
    it "renders empty log" do
      get :index, params: {id: test_entry.id, group_id: top_group.id}

      expect(response.body).to match(/keine Änderungen/)
    end

    it "renders log in correct order" do
      Fabricate(:social_account, contactable: test_entry, label: "Foo", name: "Bar")
      test_entry.update!(town: "Bern", zip_code: "3007", email: "new@hito.example.com")
      test_entry.confirm
      Fabricate(:phone_number, contactable: test_entry, label: "Foo", number: "079 123 45 67")
      Person::AddRequest::Group.create!(
        person: test_entry,
        requester: Fabricate(:person),
        body: groups(:top_group),
        role_type: Group::TopGroup::Member.sti_name
      )
      Fabricate(:phone_number, contactable: test_entry, label: "Foo", number: "079 123 45 67")
      get :index, params: {id: test_entry.id, group_id: top_group.id}

      expect(dom.all(".row.mb-3").size).to eq(1)
      expect(dom.all(".row.mb-3 .col-8 div").size).to eq(7)

      changes = (1..7).map { |x| dom.find(".row.mb-3 .col-8 div:nth-child(#{x})").text }
      expect(changes).to eq [
        "Telefonnummer +41 79 123 45 67 (Foo) wurde hinzugefügt.",
        "Zugriffsanfrage für Top Group TopGroup wurde gestellt.",
        "Telefonnummer +41 79 123 45 67 (Foo) wurde hinzugefügt.",
        "Haupt-E-Mail wurde von top_leader@example.com auf new@hito.example.com geändert.",
        "PLZ wurde von 3456 auf 3007 geändert.",
        "Ort wurde von Greattown auf Bern geändert.",
        "Social Media Adresse Bar (Foo) wurde hinzugefügt."
      ]
    end
  end
end
