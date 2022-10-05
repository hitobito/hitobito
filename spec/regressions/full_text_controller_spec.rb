# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe FullTextController, type: :controller do

  render_views

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  describe 'GET #index' do
  let(:group) { groups(:top_layer) }

    context 'with finance permissions' do
      before { sign_in(people(:top_leader)) }

      it 'renders invoices tab' do
        get :index, params: { q: 'bla' }

        expect(dom.all(:css, '.nav.nav-tabs')[0].text).to include 'Rechnungen'
      end
    end

    context 'without finance permissions' do
      let(:user) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: group).person }

      before { sign_in(user) }

      it 'does not render invoices tab' do
        get :index, params: { q: 'bla' }

        expect(dom.all(:css, '.nav.nav-tabs')[0].text).to_not include 'Rechnungen'
      end
    end
  end

end
