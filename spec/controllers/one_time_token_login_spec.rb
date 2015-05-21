# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe EventsController do

  let(:user) { people(:top_leader) }

  let(:event) { Fabricate(:course) }
  let(:group) { event.groups.first }

  it 'signs in with valid token' do
    token = user.generate_reset_password_token!
    get :show, group_id: group.id, id: event.id, onetime_token: token

    expect(assigns(:current_person)).to eq(user)
    expect(user.reload.reset_password_token).to be_blank
    is_expected.to render_template('crud/show')
  end

  it 'cannot sign in with expired token' do
    token = user.generate_reset_password_token!
    user.update_column(:reset_password_sent_at, 50.days.ago)
    get :show, group_id: group.id, id: event.id, onetime_token: token

    is_expected.to redirect_to(new_person_session_path)
    expect(user.reload.reset_password_token).to be_present
    expect(assigns(:current_person)).not_to be_present
  end

  it 'cannot sign in with wrong token' do
    token = user.generate_reset_password_token!
    get :show, group_id: group.id, id: event.id, onetime_token: 'yadayada'

    is_expected.to redirect_to(new_person_session_path)
    expect(user.reload.reset_password_token).to be_present
    expect(assigns(:current_person)).not_to be_present
  end
end
