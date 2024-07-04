# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe HouseholdAsideComponent, type: :component do
  let(:person) { people(:bottom_member) }
  let(:leader) do
    people(:top_leader).tap do |leader|
      leader.update!(birthday: 38.years.ago)
    end
  end
  let(:group) { groups(:top_group) }
  subject(:component) { described_class.new(person: person, group: group) }

  let(:member_component) { HouseholdAsideMemberComponent.new(person: person) }
  let(:member_one) { Fabricate(:person) }
  let(:member_two) { Fabricate(:person) }
  let(:rendered_component) do
    render_inline(component)
  end

  let(:helpers) do
    helpers = double("helpers")
    allow(component).to receive(:helpers).and_return(helpers)
    allow(member_component).to receive(:helpers).and_return(helpers)
    allow(component).to receive(:member_component).and_return(member_component)
    helpers
  end

  it "shows the buttons when there is a household" do
    stub_can(:show, true)
    stub_can(:create_households, true)
    create_household([member_one, member_two])
    expect(rendered_component).to have_selector(".btn", text: "Verwalten")
    expect(rendered_component).to have_selector(".btn", text: "Auflösen")
  end

  it "does show the create button when the household is empty" do
    stub_can(:show, true)
    stub_can(:create_households, true)
    expect(rendered_component).to have_selector(".btn", text: "Erstellen")
  end

  it "does not show the buttons when user does not have the right" do
    create_household([member_one, member_two])
    stub_can(:show, true)
    stub_can(:create_households, false)
    expect(rendered_component).not_to have_selector(".btn", text: "Verwalten")
    expect(rendered_component).not_to have_selector(".btn", text: "Auflösen")
  end

  it "shows create household button when household is empty" do
    stub_can(:show, true)
    stub_can(:create_households, true)
    expect(rendered_component).to have_selector(".btn", text: "Erstellen")
  end

  it "returns the humanized name of the Household model" do
    stub_can(:show, true)
    stub_can(:create_households, true)

    expect(rendered_component).to have_selector("h2", text: "Haushalt")
  end

  it "shows the members of the household" do
    stub_can(:show, true)
    stub_can(:create_households, true)
    household = create_household([member_one, member_two])
    expect(rendered_component).to have_selector("tr", text: person.full_name)
    expect(rendered_component).to have_selector("tr", text: member_one.full_name)
    expect(rendered_component).to have_selector("tr", text: member_two.full_name)
    expect(rendered_component).to have_selector("tr", count: household.members.count)
  end

  it "shows members linked if user has the right" do
    stub_can(:show, true)
    stub_can(:create_households, true)
    create_household([member_one, member_two])
    expect(rendered_component).to have_link(person.full_name)
    expect(rendered_component).to have_link(member_one.full_name)
    expect(rendered_component).to have_link(member_two.full_name)
  end

  it "shows members not linked if user does not have the right" do
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
