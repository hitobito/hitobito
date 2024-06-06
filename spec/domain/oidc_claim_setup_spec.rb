# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe OidcClaimSetup do
  let(:owner) { people(:top_leader) }
  let(:response) { :user_info }
  let(:token) { Doorkeeper::AccessToken.new(resource_owner_id: owner.id, scopes: scope.to_s) }
  let(:claim_keys) { claims.stringify_keys.keys }

  subject(:claims) { Doorkeeper::OpenidConnect::ClaimsBuilder.generate(token, response) }

  describe 'email' do
    let(:scope) { :email }

    it 'includes only person email' do
      expect(claim_keys).to eq %w(email)
      expect(claims[:email]).to eq 'top_leader@example.com'
    end
  end

  describe 'name' do
    let(:scope) { :name }

    it 'includes person name attributes' do
      expect(claim_keys).to match_array %w(first_name last_name nickname address address_care_of street housenumber postbox zip_code town country)
    end
  end

  describe 'with_roles' do
    let(:scope) { :with_roles }
    let(:role_claim) { JSON.parse(claims[:roles].first.to_json).symbolize_keys }

    it 'includes more attributes and roles' do
      expect(claim_keys).to match_array %w(
        roles
        first_name
        last_name
        nickname
        address
        company_name
        company
        email
        address_care_of
        street
        housenumber
        postbox
        zip_code
        town
        country
        gender
        birthday
        primary_group_id
        language
      )
    end

    it 'roles include json structured role information' do
      expect(claims[:roles]).to have(1).item
      expect(role_claim).to eq({
        group_id: 954199476,
        group_name: 'TopGroup',
        role: 'Group::TopGroup::Leader',
        role_class: 'Group::TopGroup::Leader',
        role_name: 'Leader',
        permissions: %w(admin finance layer_and_below_full contact_data impersonation)
      })
    end
  end

  describe 'nextcloud' do
    let(:scope) { :nextcloud }

    context 'when configured' do
      before { allow(Group::TopGroup::Leader).to receive(:nextcloud_group).and_return('test') }

      it 'contains name and groups key' do
        expect(claim_keys).to eq %w(name groups)
      end

      it 'name contain name of role' do
        expect(claims[:name]).to eq 'Top Leader'
      end

      it 'groups contain nextcloud group representation' do
        expect(claims[:groups]).to eq [
          {'gid'=>'hitobito-test', 'displayName'=>'test'}
        ]
      end
    end
  end
end
