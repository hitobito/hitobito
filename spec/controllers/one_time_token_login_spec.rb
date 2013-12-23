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

    assigns(:current_person).should == user
    user.reload.reset_password_token.should be_blank
    should render_template('crud/show')
  end

  it 'cannot sign in with expired token' do
    token = user.generate_reset_password_token!
    user.update_column(:reset_password_sent_at, 50.days.ago)
    get :show, group_id: group.id, id: event.id, onetime_token: token

    should redirect_to(new_person_session_path)
    user.reload.reset_password_token.should be_present
    assigns(:current_person).should_not be_present
  end

  it 'cannot sign in with wrong token' do
    token = user.generate_reset_password_token!
    get :show, group_id: group.id, id: event.id, onetime_token: 'yadayada'

    should redirect_to(new_person_session_path)
    user.reload.reset_password_token.should be_present
    assigns(:current_person).should_not be_present
  end
end
