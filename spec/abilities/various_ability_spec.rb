# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe VariousAbility do

  subject { ability }
  let(:ability) { Ability.new(role.person.reload) }

  context 'without admin permission' do
    let(:role) { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

    it 'may not view HitobitoLogEntry records' do
      is_expected.not_to be_able_to(:index, HitobitoLogEntry)
      is_expected.not_to be_able_to(:show, hitobito_log_entries(:info_mail))
    end
  end

  context 'with admin permission' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may not view HitobitoLogEntry records' do
      is_expected.to be_able_to(:index, HitobitoLogEntry)
      is_expected.to be_able_to(:read, hitobito_log_entries(:info_mail))
    end
  end
end
