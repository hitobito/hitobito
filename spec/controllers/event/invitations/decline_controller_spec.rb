# frozen_string_literal: true

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::Invitations::DeclineController do

  let(:bottom_member) { people(:bottom_member) }

  before { sign_in(bottom_member) }

  let(:group) { groups(:top_group) }
  let(:course) { Fabricate(:course, groups: [group], priorization: true) }
  let(:bottom_member) { people(:bottom_member) }
  let(:invitation) { Event::Invitation.create({ person_id: bottom_member.id,
                                                participation_type: 'Event::Role::Participant',
                                                event_id: course.id }) }

  context 'POST create' do
    it 'sets declined_at to invitation' do
      expect do
        post :create, params: { group_id: group.id, event_id: course.id, id: invitation.id }
      end.to change { invitation.reload.declined_at }.from(nil)
        .and change { invitation.status }.to(:declined)
    end
  end
end
