# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe RoleDecorator, :draper_with_helpers do
  let(:group) { groups(:top_group) }
  let(:role) { roles(:top_leader) }
  let(:role) { Fabricate.build(Group::TopGroup::Leader.sti_name, group: group) }
  let(:today) { Time.zone.local(2023, 11, 13) }
  let(:tomorrow) { Time.zone.tomorrow }
  let(:decorator) { described_class.new(role) }
  let(:triangle_icon) { 'i.fa.fa-exclamation-triangle' }
  let(:triangle_title) { node.find_css(triangle_icon)[0].attr('title') }

  around do |example|
    travel_to(today.midnight) do
      role.created_at = today.midnight
      example.run
    end
  end

  describe '#outdated_role_title' do
    subject(:text) { decorator.outdated_role_title  }

    it 'includes text and delete_on date' do
      role.delete_on = today
      expect(text).to eq 'Die Rolle konnte nicht wie geplant am 13.11.2023 terminiert ' \
        'werden. Falls das Speichern der Rolle diese nicht terminiert, wende dich bitte ' \
        'an den Support.'
    end

    context "FutureRole" do
      let(:role) do
        Fabricate.build(:future_role, convert_to: group.role_types.first, group: group, convert_on: today)
      end

      it "includes text and convert_on date" do
        expect(text).to eq 'Die Rolle konnte nicht wie geplant per 13.11.2023 aktiviert ' \
          'werden. Falls das Speichern der Rolle diese nicht aktiviert, wende dich bitte an ' \
          'den Support.'
      end
    end
  end

  describe '#for_aside' do
    subject(:node) { Capybara::Node::Simple.new(decorator.for_aside) }

    it 'includes role type in strong tag' do
      expect(node).to have_css(:strong, text: 'Leader')
      expect(node).not_to have_css(triangle_icon)
      expect(node).not_to have_css(:br)
    end

    it 'includes label in span tag' do
      role.label = 'test'
      expect(node).to have_css(:strong, text: 'Leader')
      expect(node).to have_css(:span, class: 'ms-1', text: '(test)')
    end

    it 'includes deletion date in span tag' do
      role.label = 'test'
      role.delete_on = tomorrow
      expect(node).to have_css(:strong, text: 'Leader')
      expect(role).not_to be_terminated
      expect(node).to have_css(:span, class: 'ms-1', text: '(test) (bis 14.11.2023)')
      expect(node).not_to have_css('br + span')
    end

    it 'includes triangle icon if outdated' do
      role.delete_on = today
      expect(node).to have_css(triangle_icon)
      expect(triangle_title).to eq 'Die Rolle konnte nicht wie geplant am 13.11.2023 terminiert ' \
        'werden. Falls das Speichern der Rolle diese nicht terminiert, wende dich bitte an ' \
        'den Support.'
    end

    it 'includes termination text on seperate line if terminated' do
      role.label = 'test'
      expect(role).to receive(:terminatable?).and_return(true)
      Roles::Termination.new(role: role, terminate_on: tomorrow).call
      expect(node).to have_css(:strong, text: 'Leader')
      expect(node).to have_css(:span, class: 'ms-1', text: '(test)')
      expect(node).to have_css('br + span', text: 'Austritt per 14.11.2023')
    end

    context "FutureRole" do
      let(:role) do
        Fabricate.build(:future_role, convert_to: group.role_types.first, group: group, convert_on: tomorrow)
      end

      it 'includes role type in strong and conversion date in span tag' do
        expect(node).to have_css(:strong, text: 'Leader')
        expect(node).to have_css(:span, class: 'ms-1', text: '(ab 14.11.2023)')
        expect(node).not_to have_css(triangle_icon)
      end

      it 'includes label in span tag' do
        role.label = 'test'
        expect(node).to have_css(:strong, text: 'Leader')
        expect(node).to have_css(:span, class: 'ms-1', text: '(test) (ab 14.11.2023)')
        expect(node).not_to have_css(triangle_icon)
      end

      it 'includes triangle icon if outdated' do
        role.convert_on = today
        expect(node).to have_css(triangle_icon)
        expect(triangle_title).to eq 'Die Rolle konnte nicht wie geplant per 13.11.2023 aktiviert ' \
          'werden. Falls das Speichern der Rolle diese nicht aktiviert, wende dich bitte an ' \
          'den Support.'
      end
    end
  end

  describe '#for_history' do
    subject(:node) { Capybara::Node::Simple.new(decorator.for_history) }

    it 'includes role type in strong tag' do
      expect(node).to have_css(:strong, text: 'Leader')
      expect(node).not_to have_css(triangle_icon)
    end

    it 'includes label in span tag' do
      role.label = 'test'
      expect(node).to have_css(:strong, text: 'Leader')
      expect(node).to have_css(:span, class: 'ms-1', text: '(test)')
    end

    it 'does include triangle if oudated' do
      role.delete_on = today
      expect(node).to have_css(triangle_icon)
      expect(triangle_title).to start_with 'Die Rolle konnte nicht wie geplant'
    end

    it 'does not include deletion date' do
      role.delete_on = tomorrow
      expect(node).to have_css(:strong, text: 'Leader')
      expect(node).not_to have_text('(bis 14.11.2023)')
    end

    it 'does not include termination' do
      expect(role).to receive(:terminatable?).and_return(true)
      Roles::Termination.new(role: role, terminate_on: tomorrow).call
      expect(node).not_to have_text('Austritt per 14.11.2023')
    end

    context "FutureRole" do
      let(:role) do
        Fabricate.build(:future_role, convert_to: group.role_types.first, group: group, convert_on: tomorrow)
      end

      it 'includes role type and conversion date' do
        expect(node).to have_css(:strong, text: 'Leader')
        expect(node).not_to have_text('(ab 14.11.2023)')
        expect(node).not_to have_css(triangle_icon)
      end

      it 'does include triangle if outdated' do
        role.convert_on = today
        expect(node).to have_css(triangle_icon)
        expect(triangle_title).to start_with 'Die Rolle konnte nicht wie geplant'
      end

      it 'does not include deletion date' do
        role.delete_on = tomorrow
        expect(node).to have_css(:strong, text: 'Leader')
        expect(node).not_to have_text('(bis 14.11.2023)')
      end

      it 'does not include termination' do
        expect(role).to receive(:terminatable?).and_return(true)
        Roles::Termination.new(role: role, terminate_on: tomorrow).call
        expect(node).not_to have_text('Austritt per 14.11.2023')
      end
    end
  end
end
