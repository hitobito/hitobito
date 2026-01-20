#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "people/_attrs.html.haml" do
  let(:top_group) { groups(:top_group) }
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:current_user) { people(:top_leader) }

  subject do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    assign(:group, group)
    assign(:qualifications, [])
    assign(:tags, [])
    person.phone_numbers.create(label: "private phone", public: false)
    allow(view).to receive_messages(parent: top_group)
    allow(view).to receive_messages(entry: PersonDecorator.decorate(person))
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:current_user).and_return(current_user)
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
    let(:current_user) {
      Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one)).person.reload
    }

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

  it "renders participation_aside partial for each participation event type" do
    travel_to "2012-01-01"
    Event::Participation.create!(event: events(:top_event), person: person, active: true)

    allow(view).to receive(:render).and_call_original
    render

    expect(view).to have_received(:render).with("participation_aside",
      anything).twice
    expect(view).to have_received(:render).with("participation_aside",
      hash_including(title: "Meine nächsten Kurse")).once
    expect(view).to have_received(:render).with("participation_aside",
      hash_including(title: "Meine nächsten Anlässe")).once
  end
end
