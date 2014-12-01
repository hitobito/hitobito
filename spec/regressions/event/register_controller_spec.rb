# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::RegisterController, type: :controller do

  render_views

  let(:event) do
    events(:top_event).tap do |e|
      e.update_column(:external_applications, true)
    end
  end

  let(:group) { event.groups.first }

  context 'GET index' do
    context 'application possible' do
      before do
        event.update_column(:application_opening_at, 5.days.ago)
      end

      context 'as external user' do
        it 'displays external login forms' do
          get :index, group_id: group.id, id: event.id
          should render_template('index')
          flash[:notice].should eq "Du musst dich einloggen um dich für den Anlass 'Top Event' anzumelden."
        end
      end
    end
  end

  context 'POST check' do
    context 'for existing person' do
      it 'generates one time login token' do
        expect do
          post :check, group_id: group.id, id: event.id, person: { email: people(:top_leader).email }
        end.to change { Delayed::Job.count }.by(1)
        should render_template('index')
        flash[:notice].should include 'Wir haben dich in unserer Datenbank gefunden.'
        flash[:notice].should include 'Wir haben dir ein E-Mail mit einem Link geschickt, wo du'
      end
    end

    context 'for non-existing person' do
      it 'displays person form' do
        post :check, group_id: group.id, id: event.id, person: { email: 'not-existing@example.com' }
        should render_template('register')
        flash[:notice].should eq 'Bitte fülle das folgende Formular aus, bevor du dich für den Anlass anmeldest.'
      end
    end
  end
end