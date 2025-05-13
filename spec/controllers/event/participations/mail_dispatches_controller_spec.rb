# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Participations::MailDispatchesController do
  include ActiveJob::TestHelper

  let(:event) { events(:top_event) }
  let(:participation) do
    Event::Participation.create!(event: event, person: people(:bottom_member))
  end
  let(:group) { event.groups.first }

  before { sign_in(user) }

  describe "POST #create" do
    context "as member" do
      let(:user) { people(:bottom_member) }

      it "unauthorized" do
        expect do
          post :create, params: {group_id: group, event_id: event, participation_id: participation, mail_type: :leader_reminder}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as leader" do
      let(:user) { people(:top_leader) }

      it "raises if mail_type is not allowed" do
        expect do
          post :create, params: {group_id: group, event_id: event, participation_id: participation, mail_type: :non_existing_mail_type}
        end.to raise_error("Invalid mail type")
      end

      it "raises if mail_type is nil" do
        expect do
          post :create, params: {group_id: group, event_id: event, participation_id: participation}
        end.to raise_error("Invalid mail type")
      end

      it "sends application confirmation email" do
        expect(LocaleSetter).to receive(:with_locale).with(person: participation.person).and_call_original
        expect do
          post :create, params: {group_id: group, event_id: event, participation_id: participation, mail_type: :event_application_confirmation}
        end.to have_enqueued_mail(Event::ParticipationMailer, :confirmation).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end
    end
  end
end
