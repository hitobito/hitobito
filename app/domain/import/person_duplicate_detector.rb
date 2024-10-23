# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Import
  class PersonDuplicateDetector
    include Import::PersonDuplicate::Attributes
    include Translatable

    # returns the first duplicate with errors if there are multiple
    def find_people_ids(attrs)
      conditions = duplicate_conditions(attrs)
      if conditions.first.present?
        ::Person.where(conditions).pluck(:id)
      else
        []
      end
    end
  end
end
