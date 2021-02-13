#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::RegisterController do
  let(:event) do
    events(:top_event).tap do |e|
      e.update_column(:external_applications, true)
    end
  end
  let(:group) { event.groups.first }

  context "GET index" do
    context "no external applications" do
      before do
        event.update_column(:external_applications, false)
      end

      context "as logged in user" do
        before { sign_in(people(:top_leader)) }

        it "displays event page" do
          get :index, params: {group_id: group.id, id: event.id}
          is_expected.to redirect_to(group_event_path(group, event))
        end
      end

      context "as external user" do
        it "displays standard login forms" do
          get :index, params: {group_id: group.id, id: event.id}
          is_expected.to redirect_to(new_person_session_path)
        end
      end
    end

    context "application possible" do
      before do
        event.update_column(:application_opening_at, 5.days.ago)
      end

      context "as logged in user" do
        before { sign_in(people(:top_leader)) }

        it "displays event page" do
          get :index, params: {group_id: group.id, id: event.id}
          is_expected.to redirect_to(group_event_path(group, event))
        end
      end

      context "as external user" do
        it "displays external login forms" do
          get :index, params: {group_id: group.id, id: event.id}
          is_expected.to render_template("index")
          expect(flash[:notice]).to eq "Du musst dich einloggen um dich für den Anlass 'Top Event' anzumelden."
        end
      end
    end

    context "application not possible" do
      before do
        event.update_attribute(:application_opening_at, 5.days.from_now)
      end

      context "as logged in user" do
        before { sign_in(people(:top_leader)) }

        it "displays event page" do
          get :index, params: {group_id: group.id, id: event.id}
          is_expected.to redirect_to(group_event_path(group, event))
          expect(flash[:alert]).to eq "Das Anmeldefenster für diesen Anlass ist geschlossen."
        end
      end

      context "as external user" do
        it "displays standard login forms" do
          get :index, params: {group_id: group.id, id: event.id}
          is_expected.to redirect_to(new_person_session_path)
          expect(flash[:alert]).to eq "Das Anmeldefenster für diesen Anlass ist geschlossen."
        end
      end
    end
  end

  context "POST check" do
    context "without email" do
      it "displays form again" do
        post :check, params: {group_id: group.id, id: event.id, person: {email: ""}}
        is_expected.to render_template("index")
        expect(flash[:alert]).to eq "Bitte gib eine E-Mail ein"
      end
    end

    context "with honeypot filled" do
      it "redirects to login" do
        post :check, params: {
          group_id: group.id,
          id: event.id,
          person: {email: "foo@example.com", verification: "Foo"},
        }

        is_expected.to redirect_to(new_person_session_path)
      end
    end

    context "for existing person" do
      it "generates one time login token" do
        expect {
          post :check, params: {group_id: group.id, id: event.id, person: {email: people(:top_leader).email}}
        }.to change { Delayed::Job.count }.by(1)
        is_expected.to render_template("index")
        expect(flash[:notice]).to include "Wir haben dich in unserer Datenbank gefunden."
        expect(flash[:notice]).to include "Wir haben dir ein E-Mail mit einem Link geschickt, wo du"
      end
    end

    context "for non-existing person" do
      it "displays person form" do
        post :check, params: {group_id: group.id, id: event.id, person: {email: "not-existing@example.com"}}
        is_expected.to render_template("register")
        expect(flash[:notice]).to eq "Bitte fülle das folgende Formular aus, bevor du dich für den Anlass anmeldest."
      end
    end
  end

  context "PUT register" do
    context "with valid data" do
      it "creates person" do
        event.update!(required_contact_attrs: [])

        expect {
          put :register, params: {group_id: group.id, id: event.id, event_participation_contact_data: {first_name: "barney", last_name: "foo", email: "not-existing@example.com"}}
        }.to change { Person.count }.by(1)

        is_expected.to redirect_to(new_group_event_participation_path(group, event))
        expect(flash[:notice]).to include "Deine persönlichen Daten wurden aufgenommen. Bitte ergänze nun noch die Angaben"
      end
    end

    context "with honeypot filled" do
      it "redirects to login" do
        event.update!(required_contact_attrs: [])

        put :register, params: {
          group_id: group.id,
          id: event.id,
          event_participation_contact_data: {
            first_name: "barney",
            last_name: "foo",
            email: "foo@example.com",
            verification: "Foo",
          },
        }
        is_expected.to redirect_to(new_person_session_path)
      end
    end

    context "with invalid data" do
      it "does not create person" do
        event.update!(required_contact_attrs: [])

        expect {
          put :register, params: {group_id: group.id, id: event.id, event_participation_contact_data: {email: "not-existing@example.com"}}
        }.not_to change { Person.count }

        is_expected.to render_template("register")
      end
    end
  end
end
