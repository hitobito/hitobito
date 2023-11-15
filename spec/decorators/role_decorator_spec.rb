# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe RoleDecorator, :draper_with_helpers do
  let(:role) { roles(:top_leader) }
  let(:today) { Time.zone.local(2023, 11, 13) }

  let(:decorator) { described_class.new(role) }

  describe '#for_aside' do
    let(:tomorrow) { Time.zone.tomorrow }
    let(:title) { node.find_css('i.fa.fa-exclamation-triangle')[0].attr('title') }

    subject(:node) { Capybara::Node::Simple.new(decorator.for_aside) }

    around do |example|
      travel_to(today.midnight) { example.run }
    end

    it 'wraps role#to_s in strong tag wihtout triangle' do
      expect(node).to have_css('strong', text: role.to_s)
      expect(node).not_to have_css('i.fa.fa-exclamation-triangle')
    end

    context 'role marked for deletion' do
      it 'does not render triangle if delete_on is in the future' do
        role.delete_on = tomorrow
        expect(node).not_to have_css('i.fa.fa-exclamation-triangle')
      end

      it 'does renders triangle if outdated' do
        role.delete_on = today
        expect(node).to have_css('i.fa.fa-exclamation-triangle')
        expect(node).to have_css('strong', text: role.to_s)
        expect(title).to eq 'Die Rolle konnte nicht wie geplant am 13.11.2023 terminiert werden. Falls das Speichern der Rolle diese nicht terminiert, wende dich bitte an den Support.'
      end
    end

    context 'role marked for conversion' do
      let(:group) { groups(:top_group) }
      let(:role) do
        Fabricate.build(:future_role, convert_to: group.role_types.first, group: group)
      end

      it 'does not render triangle if delete_on is in the future' do
        role.convert_on = tomorrow
        expect(node).not_to have_css('i.fa.fa-exclamation-triangle')
      end

      it 'does renders triangle if outdated' do
        role.convert_on = today
        expect(node).to have_css('i.fa.fa-exclamation-triangle')
        expect(node).to have_css('strong', text: role.to_s)
        expect(title).to eq 'Die Rolle konnte nicht wie geplant per 13.11.2023 aktiviert werden. Falls das Speichern der Rolle diese nicht aktiviert, wende dich bitte an den Support.'
      end
    end
  end
end
