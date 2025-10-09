#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/participations/_attrs.html.haml" do
  let(:event) { EventDecorator.decorate(Fabricate(:course, groups: [groups(:top_layer)])) }
  let(:participation) { Fabricate(:event_participation, event: event) }
  subject(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  let(:params) do
    {"action" => "show",
     "controller" => "event/participations",
     "group_id" => "1",
     "event_id" => "36"}
  end

  before do
    assign(:event, event)
    assign(:group, event.groups.first.decorate)
    assign(:answers, [])
    allow(view).to receive_messages(parent: event)
    allow(view).to receive_messages(entry: participation.decorate)
    allow(view).to receive_messages(params: params)
  end

  context "with peope_managers feature active" do
    before do
      allow(FeatureGate).to receive(:enabled?).and_call_original
      allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return true
    end

    context "with PeopleManager assigned" do
      let!(:manager) do
        Fabricate(:person).tap do |manager|
          manager.phone_numbers.create(number: "+41 44 123 45 57", label: "Privat")
          participation.person.managers << manager
        end
      end

      it "marks participations where required questions are unanswered" do
        login_as(people(:top_leader))

        expect(dom).to have_text PeopleManager.model_name.human(count: 2)
        expect(dom).to have_text manager.to_s
        expect(dom).to have_text manager.email
        expect(dom).to have_text manager.phone_numbers.first
      end
    end
  end

  def login_as(user)
    allow(controller).to receive_messages(current_user: user)
    allow(view).to receive_messages(current_user: user)
  end
end
