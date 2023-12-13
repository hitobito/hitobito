# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

describe SessionsHelper do
  include I18nHelper
  let(:group) { groups(:toppers) }

  describe '#render_self_registration_title' do
    it 'returns Group#custom_self_registration_title if present' do
      group.custom_self_registration_title = 'düdeldü'

      expect(render_self_registration_title(group)).to eq 'düdeldü'
    end

    it 'returns regular title if #custom_self_registration_title is blank' do
      expected_title = t('groups/self_registration.new.title', group_name: group.name)

      group.custom_self_registration_title = nil
      expect(render_self_registration_title(group)).to eq expected_title

      group.custom_self_registration_title = ''
      expect(render_self_registration_title(group)).to eq expected_title
    end
  end

  describe '#render_self_registration_link' do
    it 'does not render link if FeatureGate disabled' do
      allow(group).to receive(:self_registration_active).and_return(true)
      expect(render_self_registration_link).to be_blank
    end

    it 'does not render link if Group#self_registration_active?=false' do
      allow(group).to receive(:self_registration_active).and_return(false)
      expect(render_self_registration_link).to be_blank
    end

    it 'renders link if Group#self_registration_active?=true' do
      allow(group).to receive(:self_registration_active).and_return(true)
      expect(render_self_registration_link).to be_blank
    end
  end
end
