#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe SocialAccountResource, type: :resource do
  before { set_user(people(:root)) }

  describe 'serialization' do
    let!(:person) { Fabricate(:person) }
    let!(:social_account) { Fabricate(:social_account, contactable: person) }

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
