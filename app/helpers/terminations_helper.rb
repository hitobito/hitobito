# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module TerminationsHelper

  def termination_confirm_dialog_text(termination)
    key, *defaults = role_ancestors_i18n_keys(termination.role, :text)
    t(key, default: defaults)
  end

  # If the role has a delete_on set, then we render the date as text.
  # Otherwise we render a date field.
  def terminate_on_field_or_text(form, termination, **opts)
    if termination.role.delete_on?
      "#{Roles::Termination.human_attribute_name(:terminate_on)}: #{f(termination.role.delete_on)}"
    else
      form.labeled_date_field :terminate_on, **opts
    end
  end

  def termination_main_person_text(termination)
    t('roles/terminations.main_person_text', person: termination.main_person)
  end

  def termination_affected_people_text(termination)
    people = termination.affected_people.map(&:full_name).sort
    return nil unless people.present?

    t('roles/terminations.affected_people_text', affected_people: people.join(', '))
  end

  private

  def role_ancestors_i18n_keys(role, key)
    ancestors = role.class.ancestors
    role_index = ancestors.index(Role)
    relevant_ancestors = ancestors.take(role_index + 1)

    relevant_ancestors.map do |a|
      :"roles/terminations.global.#{a.name.underscore.to_sym}.#{key}"
    end
  end

end
