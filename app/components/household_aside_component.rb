# frozen_string_literal: true

class HouseholdAsideComponent < ApplicationComponent
  include Turbo::FramesHelper
  include LayoutHelper
  include UtilityHelper

  delegate :can?, to: :helpers

  I18N_PREFIX = 'person.households.aside'

  def initialize(person:)
    @person = person
    @member_component = HouseholdAsideMemberComponent.new(person: person)
  end

  private

  attr_reader :member_component, :person

  def show_component?
    return false if Rails.env.production?

    people_in_household? or show_buttons?
  end

  def section_name
    Household.model_name.human
  end

  def show_buttons?
    can?(:create_households, person)
  end

  def people_in_household?
    @person.household_people.exists?
  end

  def t(key)
    I18n.t("#{I18N_PREFIX}.#{key}")
  end
end
