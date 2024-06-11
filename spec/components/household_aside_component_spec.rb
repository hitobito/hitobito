# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe HouseholdAsideComponent, type: :component do
  let(:person) { people(:bottom_member) }
  let(:leader) do
    people(:top_leader).tap do |leader|
      leader.update!(birthday: 38.years.ago)
    end
  end
  subject(:component) { described_class.new(person: person) }
  let(:member_component) { HouseholdAsideMemberComponent.new(person: person) }
  let(:member_one) { Fabricate(:person) }
  let(:member_two) { Fabricate(:person) }
  let(:rendered_component) do
    render_inline(component).to_html
  end

  let(:helpers) do
    helpers = double('helpers')
    allow(component).to receive(:helpers).and_return(helpers)
    allow(member_component).to receive(:helpers).and_return(helpers)
    allow(component).to receive(:member_component).and_return(member_component)
    helpers
  end

  it 'shows the buttons when there is a household' do
    stub_can(:show, true)
    stub_can(:create_households, true)
    create_household([member_one, member_two])
    expect(rendered_component).to include('Verwalten')
    expect(rendered_component).to include('Auflösen')
  end

  it 'does show the create button when the household is empty' do
    stub_can(:show, true)
    stub_can(:create_households, true)
    expect(rendered_component).to include('Erstellen')
  end

  it 'does not show the buttons when user does not have the right' do
    create_household([member_one, member_two])
    stub_can(:show, true)
    stub_can(:create_households, false)
    expect(rendered_component).not_to include('Verwalten')
    expect(rendered_component).not_to include('Auflösen')
  end

  it 'shows create household button when household is empty' do
    stub_can(:show, true)
    stub_can(:create_households, true)
    expect(rendered_component).to include('Erstellen')
  end

  it 'returns the humanized name of the Household model' do
    expect(component.send(:section_name)).to eq 'Haushalt'
  end

  it 'does not show the component in production' do
    allow(Rails).to receive(:env) { 'production'.inquiry }
    stub_can(:show, true)
    stub_can(:create_households, true)
    puts rendered_component
    expect(rendered_component).not_to include('Haushalt')
  end

  it 'does show the component in development' do
    stub_can(:show, true)
    stub_can(:create_households, true)
    allow(Rails).to receive(:env) { 'development'.inquiry }
    expect(rendered_component).to include('Haushalt')
  end

  it 'shows the members of the household' do
    stub_can(:show, true)
    stub_can(:create_households, true)
    household = create_household([member_one, member_two])
    expect(rendered_component).to include(person.full_name)
    expect(rendered_component).to include(member_one.full_name)
    expect(rendered_component).to include(member_two.full_name)
    expect(rendered_component).to have_selector('table tr', count: household.members.count)
  end

  it 'shows members linked if user has the right' do
    stub_can(:show, true)
    stub_can(:create_households, true)
    create_household([member_one, member_two])
    expect(rendered_component).to have_link(person.full_name)
    expect(rendered_component).to have_link(member_one.full_name)
    expect(rendered_component).to have_link(member_two.full_name)
  end

  it 'shows members not linked if user does not have the right' do
    stub_can(:show, false)
    stub_can(:create_households, true)
    create_household([member_one, member_two])
    expect(rendered_component).not_to have_link(person.full_name)
    expect(rendered_component).not_to have_link(member_one.full_name)
    expect(rendered_component).not_to have_link(member_two.full_name)
  end

  private

  def stub_can(permission, result)
    allow(helpers).to receive(:can?).with(permission, anything).and_return(result)
  end

  def create_household(people)
    household = Household.new(person)
    people.each { |member| household.add(member) }
    household.save
    household.reload
  end
end
