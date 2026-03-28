# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Base < Filter::Base
  # Person-specific methods
  def include_ended_roles?
    false
  end

  # Returns customized roles join (e.g. for working with deleted roles)
  def roles_join
    nil
  end

  private

  def id_list(key)
    args[key] = args[key].to_s.split(ID_URL_SEPARATOR) unless args[key].is_a?(Array)
    args[key].collect!(&:to_i)
  end
end
