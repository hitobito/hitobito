#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe PhoneNumberResource, type: :resource do
  before { set_user(people(:root)) }

  describe 'serialization' do
    let!(:person) { Fabricate(:person) }
    let!(:phone_number) { Fabricate(:phone_number, contactable: person) }

    it 'works' do
      render
      data = jsonapi_data[0]
      expect(data.id).to eq(phone_number.id)
      expect(data.jsonapi_type).to eq('phone_numbers')
      expect(data.contactable_id).to eq person.id
      expect(data.contactable_type).to eq 'Person'
      expect(data.label).to eq phone_number.label
      expect(data.number).to eq phone_number.number
      expect(data.public).to eq phone_number.public
    end
  end
end
