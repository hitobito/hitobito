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

  context 'with only basic permissions role' do
    let(:role) do
      Fabricate(Group::BottomLayer::BasicPermissionsOnly.sti_name.to_sym,
                group: groups(:bottom_layer_one))
    end

    it 'may not index LabelFormat' do
      is_expected.to_not be_able_to(:index, LabelFormat)
    end

    it 'may not create LabelFormat entry' do
      is_expected.to_not be_able_to(:create, Fabricate(:label_format, person: role.person))
    end

    it 'may not update LabelFormat entry' do
      is_expected.to_not be_able_to(:update, Fabricate(:label_format, person: role.person))
    end

    it 'may not destroy LabelFormat entry' do
      is_expected.to_not be_able_to(:destroy, Fabricate(:label_format, person: role.person))
    end

    it 'may not read LabelFormat entry' do
      is_expected.to_not be_able_to(:read, Fabricate(:label_format, person: role.person))
    end
  end
end
