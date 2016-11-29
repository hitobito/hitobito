# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe LabelFormatsController do

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  
  describe 'with admin permissions' do

    before do
      sign_in(person)
    end

    it 'create layer label' do
      post :create, global: 'true', 
                    label_format: { name: 'foo layer',
                                    page_size: 'A4',
                                    landscape: false,
                                    font_size: 12,
                                    width: 60, height: 30,
                                    count_horizontal: 3,
                                    count_vertical: 8,
                                    padding_top: 5,
                                    padding_left: 5 }

      expect(LabelFormat.last.user_id).to eq(nil)
    end

    it 'create layer personalize label' do
      post :create, global: 'false',
                    label_format: { name: 'foo layer',
                                    page_size: 'A4',
                                    landscape: false,
                                    font_size: 12,
                                    width: 60, height: 30,
                                    count_horizontal: 3,
                                    count_vertical: 8,
                                    padding_top: 5,
                                    padding_left: 5 }

      expect(LabelFormat.last.user_id).to eq(person.id)
    end

  describe 'without admin permissions' do
    
    let(:person) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person }

    before do
      sign_in(person)
    end

    it 'create personalize label' do
      post :create, global: 'false',
                    label_format: { name: 'foo layer',
                                    page_size: 'A4',
                                    landscape: false,
                                    font_size: 12,
                                    width: 60, height: 30,
                                    count_horizontal: 3,
                                    count_vertical: 8,
                                    padding_top: 5,
                                    padding_left: 5 }

      expect(LabelFormat.last.user_id).to eq(person.id)
    end

    it 'can not create global label' do
      post :create, global: 'true',
                    label_format: { name: 'foo layer',
                                    page_size: 'A4',
                                    landscape: false,
                                    font_size: 12,
                                    width: 60, height: 30,
                                    count_horizontal: 3,
                                    count_vertical: 8,
                                    padding_top: 5,
                                    padding_left: 5 }

      expect(response).to have_http_status(302)
    end
  end  

  end
end 
