# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "people/_attrs.html.haml" do
  let(:top_group) { groups(:top_group) }
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }

  subject do
    allow(view).to receive_messages(current_user: current_user)
    allow(controller).to receive_messages(current_user: current_user)
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    assign(:qualifications, [])
    assign(:group, group)
    person.phone_numbers.create(label: "private phone", public: false)
    allow(view).to receive_messages(parent: top_group)
    allow(view).to receive_messages(entry: PersonDecorator.decorate(person))
  end

  context "viewed by top leader" do
    let(:current_user) { people(:top_leader) }

    it "shows roles" do
      is_expected.to have_content "Aktive Rollen"
    end
    it "does show detailed contact info" do
      is_expected.to have_content "private phone"
    end
  end

  context "viewed by person in same group" do
    let(:person) { Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one)).person.reload }
    let(:current_user) { Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one)).person.reload }

    it "does not show roles" do
      a = Ability.new(current_user)
      expect(a.can?(:show_full, person)).to be_falsey
      is_expected.not_to have_content "Aktive Rollen"
    end

    it "does show detailed contact info" do
      a = Ability.new(current_user)
      expect(a.can?(:show_details, person)).to be_truthy
      is_expected.to have_content "private phone"
    end
  end

  context "viewed by person from other group, no layer and below full" do
    let(:current_user) { Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one)).person }

    it "does not show detailed contact info" do
      expect(person.phone_numbers.first.public?).to be_falsey
      is_expected.not_to have_content "private phone"
    end
  end
end
