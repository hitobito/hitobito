# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

require 'spec_helper'

describe 'events/_actions_show.html.haml' do

  let(:participant) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: participant) }
  let(:user) { participant }
  let(:event) { participation.event }
  let(:group) { event.groups.first }

  before do
    allow(view).to receive_messages( current_user: participant, entry: event, parent: group)
    allow(view).to receive_messages(path_args: [group, event])
    allow(controller).to receive_messages(current_user: participant)
  end

  let(:dom) { Capybara::Node::Simple.new(rendered) }

  subject { dom }

  context 'to unparticipate' do
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
