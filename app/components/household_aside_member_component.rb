# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class HouseholdAsideMemberComponent < ApplicationComponent
  include Turbo::FramesHelper
  delegate :can?, to: :helpers

  def initialize(person:)
    @person = person
  end

  def call
    entries.map do |member|
      content_tag :tr do
        content_tag(:td) do
          person_entry(member)
        end
      end
    end.join.html_safe
  end

  private

  def entries
    [person, *person.household_people]
  end

  def person_entry(member)
    content_tag(:strong) do
      person_link(member)
    end
  end

  def link_person?
    can?(:show, person)
  end

  def person_link(member)
    link_to_if(link_person?, member.full_name, member, data: { turbo_frame: '_top' })
  end

  attr_reader :person
end
