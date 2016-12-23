# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'event/participations/_actions_show.html.haml' do
  let(:participant) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: participant) }
  let(:user) { participant }
  let(:event) { participation.event }
  let(:group) { event.groups.first }

  before do
    allow(view).to receive_messages(path_args: [group, event])
    allow(view).to receive_messages(entry: participation)
    allow(controller).to receive_messages(current_user: user)
    allow(view).to receive(:current_user) { user }
    controller.request.path_parameters[:action] = 'show'
    controller.request.path_parameters[:group_id] = 42
    controller.request.path_parameters[:event_id] = 42
    controller.request.path_parameters[:id] = 42
    assign(:event, event)
    assign(:group, group)
  end


  context 'last button' do
    subject { Capybara::Node::Simple.new(rendered).all('a').last }

    context 'last button per default is the change contact data button' do
      before { render }

      its([:href]) { should eq edit_group_person_path(user.groups.first, user, return_url: '/groups/42/events/42/participations/42') }
      its(:text) { should eq ' Kontaktdaten ändern' } # space because of icon
    end
  end

  context '#cancel participation' do

    let(:dom) { Capybara::Node::Simple.new(rendered) }

    subject { dom }

    context 'if application open' do

      before do
        event.update(application_opening_at: Time.now - 10.days,
                    application_closing_at: Time.now + 5.days,
                    cancel_participation_enabled: true )
      end

      it 'it renders participation' do
        render
        is_expected.to have_content 'Du bist für diesen Anlass angemeldet'
      end
    end

    context 'if application closed' do
      before do
        event.update(application_opening_at: Time.now - 10.days,
                    application_closing_at: Time.now - 5.days )
      end

      it 'renders participation' do
        render
        is_expected.not_to have_content 'Du bist für diesen Anlass angemeldet'
      end

    end
  end

end
