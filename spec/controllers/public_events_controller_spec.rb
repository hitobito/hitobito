require "spec_helper"

describe PublicEventsController do
  before do
    event.update(external_applications: true)
  end

  let(:event) { events(:top_event) }
  let(:group) { event.groups.first }

  context "GET show" do
    context "as logged in user" do
      before { sign_in(people(:top_leader)) }

      it "displays event page" do
        get :show, params: {group_id: group.id, id: event.id}

        is_expected.to redirect_to(group_event_path(group, event))
      end
    end

    context "as external user" do
      it "displays public event page" do
        get :show, params: {group_id: group.id, id: event.id}

        is_expected.not_to redirect_to(group_event_path(group, event))
        is_expected.not_to redirect_to(new_person_session_path)
      end

      it "redirect to login if external application isnt possible" do
        event.update(external_applications: false)
        get :show, params: {group_id: group.id, id: event.id}

        is_expected.to redirect_to(new_person_session_path)
      end
    end
  end
end
