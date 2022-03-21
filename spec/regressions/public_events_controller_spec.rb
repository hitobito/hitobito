# encoding: utf-8

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PublicEventsController, type: :controller do

  render_views

  let(:event) { events(:top_event) }
  let(:group) { test_entry.groups.first }

  before { event.update!(external_applications: true) }

  describe 'GET #show' do
    let(:group) { groups(:top_layer) }

    it 'renders public event form' do
      get :show, params: { group_id: group.id, id: event.id }
      expect(response).to be_ok
    end
  end

end
