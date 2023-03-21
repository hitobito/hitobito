#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

describe SocialAccountResource, type: :resource do
  let(:user) { user_role.person }

  around do |example|
    RSpec::Mocks.with_temporary_scope do
      Graphiti.with_context(double({ current_ability: Ability.new(user) })) { example.run }
    end
  end

  describe 'serialization' do
    let(:role) { roles(:bottom_member) }
    let!(:person) { role.person }
    let!(:social_account) { Fabricate(:social_account, contactable: person) }

    context 'without appropriate permission' do
      let(:user) { Fabricate(:person) }

      it 'does not expose data' do
        render
        expect(jsonapi_data).to eq([])
      end
    end

    context 'with appropriate permission' do
      let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, person: Fabricate(:person), group: role.group) }

      it 'works' do
        render
        data = jsonapi_data[0]
        expect(data.id).to eq(social_account.id)
        expect(data.jsonapi_type).to eq('social_accounts')
        expect(data.contactable_id).to eq person.id
        expect(data.contactable_type).to eq 'Person'
        expect(data.label).to eq social_account.label
        expect(data.name).to eq social_account.name
        expect(data.public).to eq social_account.public
      end
    end
  end
end
