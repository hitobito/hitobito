# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleController do

  let(:user) { people(:top_leader) }

  it 'signs in with valid token' do
    user.generate_reset_password_token!
    get :show, group_id: user.groups.first.id, id: user.id, onetime_token: user.reset_password_token

    assigns(:current_person).should be_present
    should render_template('crud/show')
  end

  it 'cannot sign in with expired token' do
    user.generate_reset_password_token!
    user.update_column(:reset_password_sent_at, 50.days.ago)
    get :show, id: user.id, onetime_token: user.reset_password_token

    should redirect_to(new_person_session_path)
    assigns(:current_person).should_not be_present
  end

  it 'cannot sign in with wrong token' do
    user.generate_reset_password_token!
    get :show, id: user.id, onetime_token: 'yadayada'

    should redirect_to(new_person_session_path)
    assigns(:current_person).should_not be_present
  end
end
