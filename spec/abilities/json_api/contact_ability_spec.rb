# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require_relative 'spec_ability_builder'

describe JsonApi::ContactAbility do
  include JsonApi::SpecAbilityBuilder

  let(:person) { Fabricate(:person) }
  let(:phone_number) { Fabricate(:phone_number, contactable: person) }

  subject { JsonApi::ContactAbility.new(main_ability, Person.all) }

  context 'when having `show_details` permission on contactable' do
    let(:main_ability) { build_ability { can :show_details, person } }

    it 'may read phone_numbers' do
      phone_number.public = true
      is_expected.to be_able_to(:read, phone_number)

      phone_number.public = false
      is_expected.to be_able_to(:read, phone_number)
    end
  end

  context 'when missing `show_details` permission on contactable' do
    let(:main_ability) { build_ability { can :show, person } }

    it 'may not read non-public phone_numbers' do
      phone_number.public = false
      is_expected.not_to be_able_to(:read, phone_number)
    end

    it 'may read public phone_numbers' do
      phone_number.public = true
      is_expected.to be_able_to(:read, phone_number)
    end
  end
end
