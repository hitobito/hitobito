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
