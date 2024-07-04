# frozen_string_literal: true

class HouseholdAsideComponent < ApplicationComponent
  include Turbo::FramesHelper
  include LayoutHelper
  include UtilityHelper

  delegate :can?, :households_path, to: :helpers

  def initialize(person:, group:)
    @person = person
    @group = group
    @member_component = HouseholdAsideMemberComponent.new(person: person)
  end

  private

  attr_reader :member_component, :person, :group

  def render?
    people_in_household? or show_buttons?
  end

  def section_name
    Household.model_name.human
  end

  def show_buttons?
    can?(:create_households, person)
  end

  def edit_button
    action_button(t(".manage"), edit_group_person_household_path(group.id, person.id), :edit,
      data: {turbo_frame: "_top"}, in_button_group: true)
  end

  def delete_button
    action_button(t(".destroy"), group_person_household_path(group.id, person.id), :"trash-alt",
      data: {method: :delete,
             confirm: I18n.t("global.confirm_delete")}, in_button_group: true)
  end

  def create_button
    action_button(t(".add"), group_person_household_path(group.id, person.id), :plus,
      data: {turbo_frame: "_top"}, in_button_group: true)
  end

  def people_in_household?
    @person.household_people.exists?
  end
end
