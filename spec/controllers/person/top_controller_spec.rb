# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::TopController do

  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'GET show' do

    context 'html' do
      it 'keeps flash' do
        get :show, params: { id: top_leader.id }
        is_expected.to redirect_to(group_person_path(top_leader.primary_group_id, top_leader.id, format: :html))
      end
    end

    context 'json' do
      it 'redirects to json' do
        get :show, params: { id: top_leader.id, user_email: 'hans@example.com', user_token: '123' }, format: :json
        is_expected.to redirect_to(group_person_path(top_leader.primary_group_id,
                                                     top_leader.id,
                                                     format: :json))
      end
    end

  end

end
