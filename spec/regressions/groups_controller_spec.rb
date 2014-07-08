# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe GroupsController, type: :controller do

  let(:group) { groups(:top_layer) }
  let(:user) { Fabricate(Group::TopLayer::Member.name.to_sym, group: group).person }

  let(:test_entry) { group }
  let(:create_entry_attrs) { { name: 'foo', type: 'Group::TopGroup', parent_id: group.id } }
  let(:update_entry_attrs) { { name: 'bar' } }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(user) }

  include_examples 'crud controller', skip: [%w(index), %w(new), %w(destroy)]


  describe 'happy path for skipped crud views' do
    render_views

    it '#index' do
      get :index
      should redirect_to(group_path(Group.root, format: :html))
    end

    describe '#show' do

      it 'has a set of links'  do
        get :show, id: groups(:bottom_layer_one).id
        response.body.should =~ /Bearbeiten/
        response.body.should_not =~ /Löschen/
        response.body.should =~ /Gruppe erstellen/
      end

      it 'has no remove link for current layer group' do
        get :show, id: groups(:top_layer).id
        response.body.should_not =~ /Löschen/
      end
    end

    it '#new' do
      templates = ['shared/_error_messages',
                   'contactable/_fields',
                   'contactable/_phone_number_fields',
                   'contactable/_social_account_fields',
                   'groups/_form',
                   'crud/new',
                   'layouts/_nav',
                   'layouts/_flash',
                   'layouts/application']

      get :new, group: { parent_id: group.id, type: 'Group::TopGroup' }
      templates.each { |template| should render_template(template) }
    end
  end

  context 'created/updated info' do
    it 'user can see created or updated info' do
      get :show, id: groups(:bottom_layer_one).id
        dom.should have_selector('dt', text: 'Erstellt')
        dom.should have_selector('dt', text: 'Geändert')
    end

    it 'user cannot see created or updated info' do
      sign_in(people(:bottom_member))
      get :show, id: groups(:top_group).id
        dom.should_not have_selector('dt', text: 'Erstellt')
        dom.should_not have_selector('dt', text: 'Geändert')
    end
  end

  context 'GET #deleted_subgroups'do
    before { groups(:bottom_group_one_one_one).destroy }

    it 'renders delete subgroups with link' do
      get :deleted_subgroups, id: groups(:bottom_group_one_one).id
      dom.should have_link 'Group 111'
    end
  end

end
