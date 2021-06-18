# encoding: utf-8

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::InvoicesController, type: :controller do

  render_views

  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:test_entry) { top_leader }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(top_leader) }

  describe 'GET index' do

    it 'renders invoice left nav rather than group hierarchy' do
      get :index, params: { id: test_entry.id, group_id: top_group.id }

      expect(response.body).to match(/Sammelrechnungen/)
      expect(response.body).not_to match(/Ohne Rollen/)
    end

  end

end
