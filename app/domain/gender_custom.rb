# frozen_string_literal: true

#  Copyright (c) 2023, GSoA. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GenderCustom

  I18N_KEY_PREFIX = 'activerecord.models.gender_custom'

  class << self
    def available
      available = {}
      I18n.t("#{I18N_KEY_PREFIX}.available").each do |salutation|
        available[salutation.first.to_s] = salutation.last
      end
      {"" => available.delete("_nil")}.merge!(available)
    end
  end

  def initialize(person)
    @person = person
  end

  def available
    result = self.class.available
    if (Person::GENDERS & result.keys).include? @person.gender.presence
      result = {@person.gender => result.delete(@person.gender)}.merge!(result)
    end
    result
  end
end
