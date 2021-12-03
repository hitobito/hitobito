# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'spec_helper'

describe HelpTexts::Renderer do
  include Capybara::RSpecMatchers
  subject { HelpTexts::Renderer.new(template, Person.new) }

  let(:controller) { PeopleController.new }
  let(:template)   { controller.view_context }

  context 'action' do
    before { controller.action_name = 'index' }

    it 'action trigger and text is empty if no help_text is present' do
      help_texts(:people_action_index).destroy!
      expect(subject.action_trigger).to be_nil
      expect(subject.action_text).to be_nil
    end

    it 'action trigger and text are present if help_text is present' do
      text = help_texts(:people_action_index)
      dom_id = template.dom_id(text)

      expect(subject.action_trigger).to have_selector('i.fa.fa-info-circle')
      expect(subject.action_trigger).to have_selector("span.help-text-trigger[@data-key=#{dom_id}]")

      expect(subject.action_text).to have_text 'test'
      expect(subject.action_text).to have_selector("div.help-text.#{dom_id}")
    end

    skip 'allows only some but not all tags' do
      %w(h1 h2 h3 h4 h5 h6 b i u blockquote ul ol li).each do |tag|
        help_text = help_texts(:people_action_index)
        help_text.update!(body: "<#{tag}>test</#{tag}>")
        expect(subject).to receive(:with_help_text).and_yield(help_text)
        expect(subject.action_text).to have_selector(tag)
      end

      %w( img em).each do |tag|
        help_text = help_texts(:people_action_index)
        help_text.update!(body: "<#{tag}>test</#{tag}>")
        expect(subject).to receive(:with_help_text).and_yield(help_text)
        expect(subject.action_text).not_to have_selector(tag)
      end
    end
  end

  context 'field' do
    it 'render_field returns nil if field is not set' do
      help_texts(:person_field_name).destroy!
      expect(subject.render_field('name')).to be_nil
    end

    it 'render_field renders icon and help_text if help_text is present' do
      text = help_texts(:person_field_name)
      dom_id = template.dom_id(text)

      expect(subject.render_field('name')).to have_selector('i.fa.fa-info-circle')
      expect(subject.render_field('name')).to have_selector("span.help-text-trigger[@data-key=#{dom_id}]")

      expect(subject.render_field('name')).to have_text 'test'
      expect(subject.render_field('name')).to have_selector("div.help-text.#{dom_id}")
    end

    it 'renders_field accepts both string and symbol' do
      expect(subject.render_field('name')).to be_present
      expect(subject.render_field(:name)).to be_present
    end

    context 'sti' do
      let(:controller) { EventsController.new }

      context 'only Event has help_text' do
        before do
          help_texts(:course_field_name).destroy!
        end

        it 'renders event text for event' do
          subject = HelpTexts::Renderer.new(template, Event.new)
          expect(subject.render_field('name')).to have_text 'base'
        end

        it 'renders event text for event' do
          subject = HelpTexts::Renderer.new(template, Event::Course.new)
          expect(subject.render_field('name')).to have_text 'base'
        end
      end

      context 'Event and Event::Course have help text' do
        it 'renders event text for event' do
          subject = HelpTexts::Renderer.new(template, Event.new)
          expect(subject.render_field('name')).to have_text 'base'
        end

        it 'renders event text for event' do
          subject = HelpTexts::Renderer.new(template, Event::Course.new)
          expect(subject.render_field('name')).to have_text 'inherited'
        end
      end
    end

  end

  context 'namespaced controller' do
    let(:controller) { Event::ParticipationsController.new }

    subject { HelpTexts::Renderer.new(template, Event::Participation.new) }

    it 'action trigger and text are present if help_text is present' do
      controller.action_name = 'index'
      expect(subject.action_trigger).to be_present
      expect(subject.action_text).to be_present
    end
  end

  context 'entry' do
    subject { HelpTexts::Renderer.new(template) }
    let(:controller) { EventsController.new }

    it 'derives from controller.model_class for index action ' do
      allow(template).to receive(:action_name).and_return('index')
      allow(template).to receive(:params).and_return(group_id: groups(:top_group).id)
      expect(subject.entry).to be_instance_of(Event)
    end

    it 'derives from controller#entry' do
      allow(template).to receive(:action_name).and_return('show')
      allow(template).to receive(:params).and_return(group_id: groups(:top_group).id)
      expect(template.controller).to receive(:entry).and_return(events(:top_course))
      expect(subject.entry).to eq events(:top_course)
    end

    it 'unwraps decorated entry from controller#entry' do
      allow(template).to receive(:action_name).and_return('show')
      allow(template).to receive(:params).and_return(group_id: groups(:top_group).id)
      expect(template.controller).to receive(:entry).and_return(events(:top_course).decorate)
      expect(subject.entry).to eq events(:top_course)
    end
  end
end
