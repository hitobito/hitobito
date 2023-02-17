# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require_relative 'spec_ability_builder'

describe JsonApi::RoleAbility do
  include JsonApi::SpecAbilityBuilder

  let(:person) { Fabricate(:person) }
  let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group), person: person) }

  subject { JsonApi::RoleAbility.new(main_ability, Person.all) }

  context 'when having `show_full` permission on person' do
    let(:main_ability) { build_ability { can :show_full, person } }

    it 'may read role' do
      is_expected.to be_able_to(:read, role)
    end
  end

  context 'when missing `show_full` permission on person' do
    let(:main_ability) { build_ability { can :show, person } }

    it 'may not read role' do
      is_expected.not_to be_able_to(:read, role)
    end
  end
end
