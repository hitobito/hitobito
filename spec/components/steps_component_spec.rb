# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe StepsComponent, type: :component do
  let(:header_css) { '.row .step-headers.offset-md-1' }
  let(:form) { double(:form_builder, object: double(:group, self_registration_require_adult_consent: false)) }
  subject(:component) { described_class.new(partials: [], form: form, step: :step) }

  before do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
      component.instance_variable_get(:@partial)
    end
  end

  def render(**args)
    render_inline(described_class.new(**args.merge(form: form)))
  end

  it 'does not render when partials are empty' do
    expect(component).not_to be_render
  end

  it 'does render header and content' do
    html = render(partials: [:main_person, :other], step: 0)
    expect(html).to have_css("#{header_css} li.active a", text: 'Personendaten')
    expect(html).to have_css('.row .step-content.main-person.active', text: 'main_person')
  end

  it 'does render header if we only have a single step' do
    html = render(partials: [:main_person], step: 0)
    expect(html).not_to have_css("#{header_css} li")
  end

  it 'renders two steps with second one active' do
    allow(I18n).to receive(:t).and_wrap_original do |m, *args|
      args.first =~/household/  ? 'Familienmitglieder' : m.call(*args)
    end

    html = render(partials: [:main_person, :household], step: 1)
    expect(html).to have_css("#{header_css} li:nth-child(1):not(.active) a", text: 'Personendaten')
    expect(html).to have_css("#{header_css} li:nth-child(2).active a", text: 'Familienmitglieder')
    expect(html).to have_css('.step-content.main-person:not(.active)')
    expect(html).to have_css('.step-content.household.active')
  end

  it 'does render second step as text when on first' do
    html = render(partials: [:main_person, :household], step: 0)
    expect(html).to have_link 'Personendaten'
    expect(html).not_to have_link 'Familienmitglieder'
  end

  it 'does render second step as text when on first' do
    html = render(partials: [:main_person, :household], step: 0)
    expect(html).to have_link 'Personendaten'
    expect(html).not_to have_link 'Familienmitglieder'
  end
end

