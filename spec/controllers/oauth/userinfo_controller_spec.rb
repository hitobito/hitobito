# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


require 'spec_helper'

describe Doorkeeper::OpenidConnect::UserinfoController do
  let(:user) { people(:top_leader) }
  let(:app) { Oauth::Application.create!(name: 'MyApp', redirect_uri: redirect_uri) }
  let(:redirect_uri) { 'urn:ietf:wg:oauth:2.0:oob' }

  describe 'GET#show' do
    let(:token) do
      app.access_tokens.create!(resource_owner_id: user.id,
                                scopes: 'openid', expires_in: 2.hours)
    end

    it 'shows the userinfo' do
      get :show, params: { access_token: token.token }
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq({
        sub: user.id.to_s
      }.deep_stringify_keys)
    end

    context 'with name scope' do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
                                  scopes: 'openid name', expires_in: 2.hours)
      end

      before do
        user.update(nickname: 'Filou',
                    street: 'Teststrasse', housenumber: '7', zip_code: '8000', town: 'Zürich',
                    country: 'CH')
      end

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq({
          sub: user.id.to_s,
          first_name: user.first_name,
          last_name: user.last_name,
          nickname: 'Filou',
          address: 'Teststrasse 7',
          address_care_of: nil,
          street: 'Teststrasse',
          housenumber: '7',
          postbox: nil,
          zip_code: '8000',
          town: 'Zürich',
          country: 'CH'
        }.deep_stringify_keys)
      end
    end

    context 'with email scope' do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
                                  scopes: 'openid email', expires_in: 2.hours)
      end

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq({
          sub: user.id.to_s,
          email: user.email
        }.deep_stringify_keys)
      end
    end

    context 'with with_roles scope' do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
                                  scopes: 'openid with_roles', expires_in: 2.hours)
      end

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to match({
          sub: user.id.to_s,
          first_name: user.first_name,
          last_name: user.last_name,
          nickname: user.nickname,
          company_name: user.company_name,
          company: user.company,
          email: user.email,
          address: user.address,
          address_care_of: user.address_care_of,
          street: user.street,
          housenumber: user.housenumber,
          postbox: user.postbox,
          zip_code: user.zip_code,
          town: user.town,
          country: user.country,
          gender: user.gender,
          birthday: user.birthday.to_s.presence,
          primary_group_id: user.primary_group_id,
          language: user.language,
          roles: [
            {
              group_id: user.roles.first.group_id,
              group_name: user.roles.first.group.name,
              role: 'Group::TopGroup::Leader',
              role_class: 'Group::TopGroup::Leader',
              role_name: 'Leader',
              permissions: ['admin', 'finance', 'layer_and_below_full', 'contact_data', 'impersonation']
            }
          ]
        }.deep_stringify_keys)
      end
    end

    context 'with nextcloud scope' do
      let(:token) do
        app.access_tokens.create!(
          resource_owner_id: user.id,
          scopes: 'openid email nextcloud',
          expires_in: 2.hours
        )
      end

      before do
        user.update(first_name: 'Tom', last_name: 'Tester')

        temp_group = Group::GlobalGroup.new(id: 1024, name: 'Test', parent: groups(:top_layer))
        admin_role = Fabricate(:'Group::GlobalGroup::Leader', person: user, group: temp_group)
        admin_role.class.nextcloud_group = 'Admins'

        # second role resulting in the same mapping, intended to test deduplication
        Fabricate(:'Group::GlobalGroup::Leader', person: user, group: temp_group)

        group_role = Fabricate(:'Group::GlobalGroup::Member', person: user, group: temp_group)
        group_role.class.nextcloud_group = true
      end

      after do
        Group::GlobalGroup::Leader.nextcloud_group = false
        Group::GlobalGroup::Member.nextcloud_group = false
      end

      it 'has assumptions' do
        expect(Settings.groups.nextcloud.enabled).to be true # in the test-env

        expect(user.to_s).to eq 'Tom Tester'
        expect(user).to have(4).roles
        expect(user.email).to eq 'top_leader@example.com'
      end

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200

        expect(JSON.parse(response.body)).to eq({
          sub: user.id.to_s,
          email: 'top_leader@example.com',
          name: 'Tom Tester',
          groups: [
            { displayName: 'Admins', gid: 'hitobito-Admins' },
            { displayName: 'Test', gid: '1024' }
          ]
        }.deep_stringify_keys)
      end
    end
  end
end
