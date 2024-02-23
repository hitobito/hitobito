# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Roles::Termination
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :role

  attribute :terminate_on, :date

  validates :role, :terminate_on, presence: true
  validate :validate_terminate_on
  validate :terminatable

  def call
    return false unless valid?

    role.delete_on = terminate_on
    role.write_attribute(:terminated, true)
    role.save!

    true
  end

  def affected_roles
    [role]
  end

  def main_person
    role.person
  end

  def affected_people
    []
  end

  private

  def validate_terminate_on
    return if terminate_on.nil?

    if terminate_on < minimum_termination_date
      errors.add(:terminate_on, :too_early, date: I18n.l(minimum_termination_date))
    end

    if terminate_on > maximum_termination_date
      errors.add(:terminate_on, :too_late, date: I18n.l(maximum_termination_date))
    end
  end

  def minimum_termination_date
    1.day.from_now.to_date
  end

  def maximum_termination_date
    1.year.from_now.end_of_year.to_date
  end

  def terminatable
    return if role.nil? || role.terminatable?

    errors.add(:role, :not_terminatable) unless role.terminatable?
  end

end
