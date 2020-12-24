# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe GroupSettingsController do

  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:setting_params) do
    { username: 'gollum',
      password: 'my-precious',
      provider: 'aspsms' }
  end
  let(:setting) { group.settings(:text_message_provider) }

  before { sign_in(top_leader) }

  describe 'GET #new' do
  end

  describe 'POST #update' do
    it 'initializes setting on first update' do
      patch :update, params: { group_id: group.id, id: 'text_message_provider',
                               rails_settings_setting_object: setting_params }

      expect(setting.username).to eq('gollum')
      expect(setting.password).to eq('my-precious')
      expect(setting.provider).to eq('aspsms')
    end

    it 'only concerns available attrs when updating' do
      setting_params[:gollum] = 'smeagol'
      patch :update, params: { group_id: group.id, id: 'text_message_provider',
                               rails_settings_setting_object: setting_params }

      expect(setting.gollum).to be_nil
    end

    it 'updates existing setting' do
      group.settings(:text_message_provider).update!(setting_params)

      setting_params[:username] = 'frodo'
      setting_params[:password] = 'his-precious'

      patch :update, params: { group_id: group.id, id: 'text_message_provider',
                               rails_settings_setting_object: setting_params }

      setting.reload
      expect(setting.username).to eq('frodo')
      expect(setting.password).to eq('his-precious')
      expect(setting.provider).to eq('aspsms')
    end

    it 'cannot update setting if no permission' do
    end

  end
end
