#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ServiceToken do

  describe '#dynamic user' do
    it 'gets layer_and_below_read permissions when token has layer_and_below_read' do
      token = ServiceToken.new(layer: groups(:top_layer), permission: :layer_and_below_read)
      expect(token.dynamic_user.roles).to have(1).item
      expect(token.dynamic_user.roles.first.group).to eq groups(:top_layer)
      expect(token.dynamic_user.roles.first.permissions).to eq [:layer_and_below_read]
    end

    it 'gets layer_read permissions when token does have layer_read' do
      token = ServiceToken.new(layer: groups(:top_layer), permission: :layer_read)
      expect(token.dynamic_user.roles).to have(1).item
      expect(token.dynamic_user.roles.first.group).to eq groups(:top_layer)
      expect(token.dynamic_user.roles.first.permissions).to eq [:layer_read]
    end

    it 'gets layer_and_below_full permissions when token does have layer_and_below_full' do
      token = ServiceToken.new(layer: groups(:top_layer), permission: :layer_and_below_full)
      expect(token.dynamic_user.roles).to have(1).item
      expect(token.dynamic_user.roles.first.group).to eq groups(:top_layer)
      expect(token.dynamic_user.roles.first.permissions).to eq [:layer_and_below_full]
    end

    it 'gets layer_full permissions when token does have layer_full' do
      token = ServiceToken.new(layer: groups(:top_layer), permission: :layer_full)
      expect(token.dynamic_user.roles).to have(1).item
      expect(token.dynamic_user.roles.first.group).to eq groups(:top_layer)
      expect(token.dynamic_user.roles.first.permissions).to eq [:layer_full]
    end
  end

  context 'callbacks' do
    it 'generates token on create' do
      token = ServiceToken.create(name: 'Token', layer: groups(:top_group)).token
      expect(token).to be_present
      expect(token.length).to eq(50)
    end

    it 'does not generate token on update' do
      service_token = service_tokens(:permitted_top_layer_token)
      token = service_token.token

      service_token.update(description: 'new description')
      expect(service_token.token).to eq(token)
    end
  end
end
