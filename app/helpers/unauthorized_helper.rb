# frozen_string_literal: true

#  Copyright (c) 2022-2022, Puzzle ITC GmbH. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UnauthorizedHelper
  def hide_signup_links?
    [
      new_person_session_path,
      new_person_password_path,
      new_person_confirmation_path
    ].one? do |path|
      current_page?(path)
    end
  end
end
