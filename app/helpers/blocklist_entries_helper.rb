# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module BlocklistEntriesHelper
  def blocklist_hash_attrs_sentence
    Person::BlocklistDetector.hash_attrs.map { Person.human_attribute_name(_1) }.to_sentence
  end
end
