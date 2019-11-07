# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'spec_helper'

describe HelpTexts::Renderer do
  include Capybara::RSpecMatchers
  subject { HelpTexts::Renderer.new(template) }

  let(:controller) { PeopleController.new }
  let(:template)   { controller.view_context }

  context 'action' do
    before { controller.action_name = 'index' }

    it 'action trigger and text is empty if no help_text is present' do
      expect(subject.action_trigger).to be_nil
      expect(subject.action_text).to be_nil
    end

    it 'action trigger and text are present if help_text is present' do
      text = HelpText.create!(controller: 'people', model: 'person', kind: 'action', name: 'index', body: 'test')
      dom_id = template.dom_id(text)

      expect(subject.action_trigger).to have_selector('i.fa.fa-info-circle')
      expect(subject.action_trigger).to have_selector("span.help-text-trigger[@data-key=#{dom_id}]")

      expect(subject.action_text).to have_text 'test'
      expect(subject.action_text).to have_selector("div.help-text.#{dom_id}")
    end
  end

  context 'field' do
    it 'render_field is returns nil if field is not set' do
      expect(subject.render_field('name')).to be_nil
    end

    it 'render_field renders icon and help_text if help_text is present' do
      text = HelpText.create!(controller: 'people', model: 'person', kind: 'field', name: 'name', body: 'test')
      dom_id = template.dom_id(text)

      expect(subject.render_field('name')).to have_selector('i.fa.fa-info-circle')
      expect(subject.render_field('name')).to have_selector("span.help-text-trigger[@data-key=#{dom_id}]")

      expect(subject.render_field('name')).to have_text 'test'
      expect(subject.render_field('name')).to have_selector("div.help-text.#{dom_id}")
    end

    it 'renders_field accepts both string and symbol' do
      HelpText.create!(controller: 'people', model: 'person', kind: 'field', name: 'name', body: 'test')

      expect(subject.render_field('name')).to be_present
      expect(subject.render_field(:name)).to be_present
    end
  end

  context 'field with sti' do
    let(:controller) { EventsController.new }

    before do
      HelpText.create!(controller: 'events', model: 'event', kind: 'field', name: 'name', body: 'base')
    end

    it 'renders event for both event and course' do
      expect(subject.render_field('name', Event.new)).to have_text 'base'
      expect(subject.render_field('name', Event::Course.new)).to have_text 'base'
    end

    it 'renders course specific text if present' do
      HelpText.create!(controller: 'events', model: 'event/course', kind: 'field', name: 'name', body: 'inherited')
      expect(subject.render_field('name', Event.new)).to have_text 'base'
      expect(subject.render_field('name', Event::Course.new)).to have_text 'inherited'
    end

  end

  context 'namespaced controller' do
    let(:controller) { Event::ParticipationsController.new }

    before do
      HelpText.create!({
        controller: 'event/participations',
        model: 'event/participation',
        kind: 'action',
        name: 'index',
        body: 'test'
      })
    end

    it 'action trigger and text are present if help_text is present' do
      controller.action_name = 'index'
      expect(subject.action_trigger).to be_present
      expect(subject.action_text).to be_present
    end
  end
end
