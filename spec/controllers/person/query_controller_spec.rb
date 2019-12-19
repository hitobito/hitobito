# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::QueryController do

  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'GET index' do
    it 'queries all people' do
      Fabricate(:person, first_name: 'Pascal')
      Fabricate(:person, last_name: 'Opassum')
      Fabricate(:person, last_name: 'Anything')
      get :index, params: { q: 'pas' }

      expect(response.body).to match(/Pascal/)
      expect(response.body).to match(/Opassum/)
    end
  end

end
