# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito


require 'spec_helper'

describe SelfRegistrationReasonAbility do

  let(:entry) { Fabricate(:self_registration_reason) }
  let(:ability) { Ability.new(role.person.reload) }

  context 'with admin permission' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may index SelfRegistrationReason records' do
      expect(ability).to be_able_to(:index, SelfRegistrationReason)
    end

    it 'may manage SelfRegistrationReason records' do
      expect(ability).to be_able_to(:manage, entry)
    end
  end

  context 'without admin permission' do
    let(:role) { Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)) }

    it 'may not index SelfRegistrationReason records' do
      expect(ability).not_to be_able_to(:index, SelfRegistrationReason)
    end

    it 'may not show SelfRegistrationReason records' do
      expect(ability).not_to be_able_to(:show, entry)
    end

    %w[create update destroy].each do |action|
      it "may not #{action} SelfRegistrationReason records" do
        expect(ability).not_to be_able_to(action.to_sym, entry)
      end
    end
  end
end
