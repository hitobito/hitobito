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

  around do |example|
    travel_to(today.midnight) { example.run }
  end

  context 'for_aside' do
    let(:node) { Capybara::Node::Simple.new(decorator.for_aside) }
    let(:decorated_name) { decorator.for_aside }

    it 'includes bis' do
      role.delete_on = Time.zone.local(2023, 12, 12)

      formatted_name = '<strong>Leader</strong>&nbsp;(bis 12.12.2023)' 

      expect(decorated_name).to eq(formatted_name)
    end

    it 'includes outdated info' do
      role.delete_on = Time.zone.local(2023, 1, 1)
      warning_title = node.find_css('i.fas.fa-exclamation-triangle')[0].attr('title')

      expect(node).to have_css('i.fas.fa-exclamation-triangle')
      expect(warning_title).to eq 'Die Rolle konnte nicht wie geplant am 01.01.2023 terminiert werden. Falls das Speichern der Rolle diese nicht terminiert, wende dich bitte an den Support.'
      expect(decorated_name).to include('<strong>Leader</strong>&nbsp;(bis 01.01.2023)')
    end

    it 'includes label' do
      role.label = '42'
      formatted_name = '<strong>Leader</strong>&nbsp;(42)' 

      expect(decorated_name).to eq(formatted_name)
    end

    context 'future role' do
      let(:role) do
        FutureRole.new(convert_on: Time.zone.local(2023, 12, 12),
                      convert_to: Group::BottomLayer::Leader)
      end

      it 'includes ab' do
        formatted_name = '<strong>Leader</strong>&nbsp;(ab 12.12.2023)' 

        expect(decorated_name).to eq(formatted_name)
      end

      it 'includes ab and label' do
        role.label = '42'
        formatted_name = '<strong>Leader</strong>&nbsp;(42)&nbsp;(ab 12.12.2023)' 

        expect(decorated_name).to eq(formatted_name)
      end
    end

  end

  context 'for_history' do
    let(:node) { Capybara::Node::Simple.new(decorator.for_history) }
    let(:decorated_name) { decorator.for_history }

    it 'role#to_s without strong tag and without triangle' do
      expect(node).not_to have_css('strong', text: role.to_s)
      expect(node).not_to have_css('i.fas.fa-exclamation-triangle')
    end

    it 'never includes bis and is not bold' do
      role.delete_on = Time.zone.local(2023, 12, 12)

      expect(decorated_name).to eq('Leader')
    end

    it 'includes outdated info and is not bold' do
      role.delete_on = Time.zone.local(2023, 1, 1)
      warning_title = node.find_css('i.fas.fa-exclamation-triangle')[0].attr('title')

      expect(node).to have_css('i.fas.fa-exclamation-triangle')
      expect(warning_title).to eq 'Die Rolle konnte nicht wie geplant am 01.01.2023 terminiert werden. Falls das Speichern der Rolle diese nicht terminiert, wende dich bitte an den Support.'
      expect(decorated_name).not_to include('<strong>Leader</strong>&nbsp;(bis 01.01.2023)')
      expect(decorated_name).to include('Leader')
    end

    it 'includes label and is not bold' do
      role.label = '42'
      formatted_name = 'Leader&nbsp;(42)' 

      expect(decorated_name).to eq(formatted_name)
    end

    context 'future role' do
      let(:role) do
        FutureRole.new(convert_on: Time.zone.local(2023, 12, 12),
                      convert_to: Group::BottomLayer::Leader)
      end

      it 'never includes ab and is not bold' do
        expect(decorated_name).to eq('Leader')
      end
    end

  end
end
