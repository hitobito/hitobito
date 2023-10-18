# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe :admin_left_nav, js: true do

  context 'SelfRegistrationReason' do
    let(:path) { label_formats_path }

    context 'with necessary ability' do
      before { sign_in(people(:root)) }

      it 'is visible if self registration is enabled' do
        allow(FeatureGate).to receive(:enabled?).with(:self_registration_reason).and_return(true)
        visit path
        expect(page.find('nav#page-navigation')).to have_link(href: self_registration_reasons_path)
      end
    end

    context 'without necessary ability' do
      before { sign_in(people(:bottom_member)) }

      it 'is not visible if self registration is enabled' do
        allow(FeatureGate).to receive(:enabled?).with('self_registration_reason').and_return(true)
        visit path
        expect(page.find('nav#page-navigation')).to have_no_link(href: self_registration_reasons_path)
      end

      it 'is not visible if self registration is disabled' do
        allow(FeatureGate).to receive(:enabled?).with('self_registration_reason').and_return(false)
        visit path
        expect(page.find('nav#page-navigation')).to have_no_link(href: self_registration_reasons_path)
      end
    end
  end


end
