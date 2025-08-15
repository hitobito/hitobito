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

      it "redirect to login if external application is not possible" do
        event.update(external_applications: false)
        get :show, params: {group_id: group.id, id: event.id}

        is_expected.to redirect_to(new_person_session_path)
      end

      it "sets flash if application_period is closed" do
        event.update!(application_closing_at: Time.zone.yesterday)
        get :show, params: {group_id: group.id, id: event.id}
        expect(flash[:alert]).to eq "Das Anmeldefenster für diesen Anlass ist geschlossen."
      end

      it "sets flash if no places are available" do
        event.update!(maximum_participants: 1)
        Fabricate(Event::Role::Participant.sti_name, participation: Fabricate(:event_participation, event:))
        get :show, params: {group_id: group.id, id: event.id}
        expect(flash[:alert]).to eq "Die maximale Teilnehmeranzahl für diesen Anlass ist bereits erreicht."
      end

      describe "course" do
        let(:event) { events(:top_course) }

        before {
          Fabricate(Event::Course::Role::Participant.sti_name,
            participation: Fabricate(:event_participation, event:, active: true))
        }

        it "does set flash if neither places nor waiting_list is available" do
          event.update!(maximum_participants: 1, waiting_list: false)
          get :show, params: {group_id: group.id, id: event.id}
          expect(flash[:alert]).to eq "Die maximale Teilnehmeranzahl für diesen Anlass ist bereits erreicht."
        end

        it "does not set flash if no places but waiting_list is available" do
          event.update!(maximum_participants: 1, waiting_list: true)
          get :show, params: {group_id: group.id, id: event.id}
          expect(flash[:alert]).to be_nil
        end
      end

      describe "with views" do
        render_views
        let(:page) { Capybara::Node::Simple.new(response.body) }

        before { event.update(external_applications: true) }

        it "renders application attrs" do
          get :show, params: {group_id: group.id, id: event.id}
          expect(page).to have_css("h2", text: "Anmeldung")
        end

        it "hides application if configured to do so" do
          controller.render_application_attrs = false
          get :show, params: {group_id: group.id, id: event.id}
          expect(page).not_to have_css("h2", text: "Anmeldung")
        end

        it "does not autofocuses anything" do
          get :show, params: {group_id: group.id, id: event.id}
          expect(page).not_to have_css("input[autofocus]")
        end
      end
    end
  end
end
