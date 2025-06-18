# frozen_string_literal: true

#  Copyright (c) 2025, Hitobito. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'rails_helper'

describe PeopleFilterCriterionsController do
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader)}

  before do
    sign_in(person)
    allow(controller).to receive(:group).and_return(group)
  end

  describe 'POST #create' do
    it 'adds the criterion to the active criterias in flash' do
      post :create, params: { group_id: group.id, criterion: 'role' }, as: :turbo_stream
      expect(flash[:people_filter_active_criterias]).to include('role')
    end
  end

  describe 'DELETE #destroy' do
    it 'removes the criterion from the active criterias in flash' do
      delete :destroy, params: { group_id: group.id, criterion: 'tag' }, as: :turbo_stream
      expect(flash[:people_filter_active_criterias]).to eq([])
    end
  end
end
