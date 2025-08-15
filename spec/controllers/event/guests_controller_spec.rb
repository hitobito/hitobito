# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::GuestsController do
  let(:group) { groups(:top_layer) }

  let!(:other_event) do
    other = Fabricate(:event, groups: [group])
    other.dates << Fabricate(:event_date, event: other, start_at: event.dates.first.start_at)
    other
  end

  let(:event) do
    event = Fabricate(:event, groups: [group], guest_limit: 3)
    event.questions << Fabricate(:event_question, event: event)
    event.questions << Fabricate(:event_question, event: event)
    event.dates << Fabricate(:event_date, event: event)
    event
  end

  let(:participation) do
    Fabricate(:event_participation, event: event, participant: user).tap do |p|
      Fabricate(Event::Role::Participant.name.to_sym, participation: p)
      p.answers.detect { |a| a.question_id == event.questions[0].id }.update!(answer: "juhu")
      p.answers.detect { |a| a.question_id == event.questions[1].id }.update!(answer: "blabla")
    end
  end

  let(:user) { people(:top_leader) }

  before do
    sign_in(user)
  end

  context "GET new" do
    context "for event allowing guests" do
      before { get :new, params: {group_id: group.id, event_id: event.id, id: participation.id} }

      it "displays wizard" do
        wizard = assigns(:wizard)
        expect(wizard.event.id).to eq(event.id)
        expect(wizard.guest_of.id).to eq(participation.id)
        expect(wizard.current_step).to eq(0)
        is_expected.to render_template("event/guests/new")
      end
    end

    context "for event not allowing guests" do
      before do
        event.update!(guest_limit: 0)
        get :new, params: {group_id: group.id, event_id: event.id, id: participation.id}
      end

      it "redirects to the event page" do
        is_expected.to redirect_to(group_event_path(group.id, event.id))
        expect(flash[:alert]).to eq "Du kannst in diesem Anlass keine weiteren Gäste hinzufügen."
      end
    end

    context "when guest limit already reached" do
      before do
        event.update!(guest_limit: 1)
        guest = Fabricate(:event_guest, main_applicant: participation)
        Fabricate(:event_participation, event: event, participant: guest)
        get :new, params: {group_id: group.id, event_id: event.id, id: participation.id}
      end

      it "redirects to the event page" do
        is_expected.to redirect_to(group_event_path(group.id, event.id))
        expect(flash[:alert]).to eq "Du kannst in diesem Anlass keine weiteren Gäste hinzufügen."
      end
    end

    context "adding a guest for someone else" do
      before do
        participation.update!(participant: people(:bottom_member))
      end

      it "refuses to add guests (for now)" do
        expect do
          get :new, params: {group_id: group.id, event_id: event.id, id: participation.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context "GET new step 2" do
    context "for event allowing guests" do
      before { get :new, params: {group_id: group.id, event_id: event.id, id: participation.id, step: 1} }

      it "displays wizard" do
        wizard = assigns(:wizard)
        expect(wizard.event.id).to eq(event.id)
        expect(wizard.guest_of.id).to eq(participation.id)
        expect(wizard.current_step).to eq(1)
        is_expected.to render_template("event/guests/new")
      end
    end

    context "for event not allowing guests" do
      before do
        event.update!(guest_limit: 0)
        get :new, params: {group_id: group.id, event_id: event.id, id: participation.id, step: 1}
      end

      it "redirects to the event page" do
        is_expected.to redirect_to(group_event_path(group.id, event.id))
        expect(flash[:alert]).to eq "Du kannst in diesem Anlass keine weiteren Gäste hinzufügen."
      end
    end

    context "when guest limit already reached" do
      before do
        event.update!(guest_limit: 1)
        guest = Fabricate(:event_guest, main_applicant: participation)
        Fabricate(:event_participation, event: event, participant: guest)
        get :new, params: {group_id: group.id, event_id: event.id, id: participation.id}
      end

      it "redirects to the event page" do
        is_expected.to redirect_to(group_event_path(group.id, event.id))
        expect(flash[:alert]).to eq "Du kannst in diesem Anlass keine weiteren Gäste hinzufügen."
      end
    end
  end

  context "POST create step 2" do
    let(:contact_data) {
      {
        first_name: "Tom",
        last_name: "Tester",
        email: "tester@puzzle.ch"
      }
    }
    let(:participation_data) { {} }
    let(:params) {
      {group_id: group.id, event_id: event.id, id: participation.id, step: 1,
       wizards_register_new_event_guest_wizard: {
         new_event_guest_contact_data_form: contact_data,
         new_event_guest_participation_form: participation_data
       }}
    }

    before do
      # rubocop:todo Layout/LineLength
      # call this before the expectation, to make sure the participation is already persisted and does not count towards the change assertions
      # rubocop:enable Layout/LineLength
      participation
    end

    context "valid guest" do
      it "is persisted" do
        expect { post :create, params: params }
          .to change(Event::Guest, :count).by(1)
          .and change(Event::Participation, :count).by(1)
      end
    end

    context "invalid guest" do
      let(:contact_data) {
        {
          first_name: "Tom",
          last_name: "Tester",
          email: "tester@puzzle.ch",
          language: "something other than a language code"
        }
      }

      it "is not persisted" do
        expect { post :create, params: params }
          .to change(Event::Guest, :count).by(0)
          .and change(Event::Participation, :count).by(0)
      end
    end

    context "guest with missing required contact attrs" do
      before { event.update!(required_contact_attrs: ["zip_code"]) }

      it "is not persisted" do
        expect { post :create, params: params }
          .to change(Event::Guest, :count).by(0)
          .and change(Event::Participation, :count).by(0)
      end
    end

    context "when the event does not allow guests" do
      before { event.update!(guest_limit: 0) }

      it "is not persisted" do
        expect { post :create, params: params }
          .to change(Event::Guest, :count).by(0)
          .and change(Event::Participation, :count).by(0)
      end
    end

    context "when the main_applicant's guest limit is already used up" do
      before do
        event.update!(guest_limit: 1)
        guest = Fabricate(:event_guest, main_applicant: participation)
        Fabricate(:event_participation, event: event, participant: guest)
      end

      it "is not persisted" do
        expect { post :create, params: params }
          .to change(Event::Guest, :count).by(0)
          .and change(Event::Participation, :count).by(0)
      end
    end
  end
end
