# encoding: utf-8

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
      Fabricate(:phone_number, contactable: test_entry, label: "Foo", number: "23425 1341 12")
      Person::AddRequest::Group.create!(
        person: test_entry,
        requester: Fabricate(:person),
        body: groups(:top_group),
        role_type: Group::TopGroup::Member.sti_name)
      Fabricate(:phone_number, contactable: test_entry, label: "Foo", number: "43 3453 45 254")

      get :index, params: {id: test_entry.id, group_id: top_group.id}

      expect(dom.all("h4").size).to eq(1)
      expect(dom.all("#content div").size).to eq(12)
    end
  end
end
