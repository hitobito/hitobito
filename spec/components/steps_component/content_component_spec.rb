# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe StepsComponent::ContentComponent, type: :component do
  let(:form) { double(:form) }
  let(:iterator) { double(:iterator, index: 1, last?: false) }
  subject(:component) do
    described_class.new(partial: :partial, partial_iteration: iterator, form: form, step: 0)
  end

  it 'back link renders link for stimulus controller iterator based index' do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
      back_link = Capybara::Node::Simple.new(component.back_link)
      expect(back_link).to have_link 'Zurück'
      expect(back_link).to have_css '.link.cancel[data-index=0]', text: 'Zurück'
      expect(back_link).to have_css ".link.cancel[data-action='steps-component#back']",
                                    text: 'Zurück'
    end
    render_inline(component)
  end

  it 'next button renders form button with step value' do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
      expect(form).to receive(:button)
        .with('Weiter',
              { class: 'btn btn-sm btn-primary mt-2',
                data: { disable_with: 'Weiter' }, name: :step, value: 1 })
      component.next_button
    end
    render_inline(component)
  end

  it 'next button accepts specific label' do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
      expect(form).to receive(:button)
        .with('Test',
              { class: 'btn btn-sm btn-primary mt-2',
                data: { disable_with: 'Test' }, name: :step, value: 1 })
      component.next_button('Test')
    end
    render_inline(component)
  end

  context 'real partial' do
    let(:object) do
      SelfRegistration.new(group: groups(:top_group), params: {})
    end
    let(:form) do
      StandardFormBuilder.new(:obj, object, vc_test_controller.view_context,
                              { builder: StandardFormBuilder })
    end
    let(:component) do
      described_class.new(partial: 'groups/self_registration/main_person',
                          partial_iteration: iterator,
                          form: form, step: 0)
    end
    let(:iterator) { double(:iterator, index: 0, last?: false) }
    let(:policy_finder) { double(:policy_finder, acceptance_needed?: true, groups: []) }
    let(:entry) { double(:entry, partials: [:partial], require_adult_consent: false) }

    subject(:html) { render_inline(component) }

    before do
      allow_any_instance_of(ActionView::Base).to receive(:entry).and_return(entry)
      allow_any_instance_of(ActionView::Base).to receive(:policy_finder).and_return(policy_finder)
    end

    def stub_test_person
      stub_const("TestPerson", Class.new(SelfRegistration::Person) do # rubocop:disable Lint/ConstantDefinitionInBlock
        yield self
        self.attrs += [:privacy_policy_accepted]  ## needed for internal validations
        def requires_adult_consent?; false; end
      end)
      expect(object).to receive(:main_person).and_return(TestPerson.new)
    end


    it 'does not render if partial index is above current step' do
      expect(iterator).to receive(:index).and_return(1)
      expect(component).not_to be_render
    end

    it 'renders first_name last_name and email' do
      expect(html).to have_field('Haupt-E-Mail')
      expect(html).to have_field('Vorname')
      expect(html).to have_field('Nachname')
    end

    it 'does not render attrs that are not listed on model' do
      stub_test_person do |test_person|
        test_person.attrs = [:email]
        test_person.required_attrs = [:email]
      end

      expect(html).to have_field('Haupt-E-Mail')
      expect(html).not_to have_field('Vorname')
      expect(html).not_to have_field('Nachname')
    end

    it 'can control if field is required' do
      stub_test_person do |test_person|
        test_person.attrs = [:email, :first_name]
        test_person.required_attrs = [:email]
      end
      expect(html).to have_css('label.required', text: 'Haupt-E-Mail')
      expect(html).to have_css('label', text: 'Vorname')
      expect(html).not_to have_css('label.required', text: 'Vorname')
    end

    it 'shows check if policy_finder needs acceptance' do
      expect(policy_finder).to receive(:acceptance_needed?).and_return(true)
      expect(html).to have_field('Ich erkläre mich mit den folgenden Bestimmungen einverstanden:')
    end

    it 'hides check if policy_finder needs acceptance but we are not on the last page' do
      expect(entry).to receive(:partials).and_return([:one, :two])
      expect(policy_finder).not_to receive(:acceptance_needed?)
      expect(html).not_to have_field('Ich erkläre mich mit den folgenden Bestimmungen einverstanden:')
    end
  end
end
