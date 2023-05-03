# frozen_string_literal: true

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::QueryController do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  context 'GET index' do
    context 'as top_leader' do
      before { sign_in(top_leader) }

      it 'queries all people' do
        Fabricate(:person, first_name: 'Pascal')
        Fabricate(:person, last_name: 'Opassum')
        Fabricate(:person, last_name: 'Anything')
        get :index, params: { q: 'pas' }

        expect(response.body).to match(/Pascal/)
        expect(response.body).to match(/Opassum/)
      end
    end

    context 'as bottom_member' do
      before { sign_in(bottom_member) }

      it 'queries all people limited by permission given' do
        Fabricate(Group::TopGroup::Member.to_s,
                  person: Fabricate(:person, first_name: 'Pascal'),
                  group: groups(:top_group))
        get :index, params: { q: 'pas', limit_by_permission: :update }

        expect(response.body).to_not match(/Pascal/)
      end
    end
  end

end
