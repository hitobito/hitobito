# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is used to remove specific data of a person
# What will be deleted is implemented per wagon
# Keep in mind to also purge PaperTrail::Versions which also persists the data
class People::Minimizer

  def initialize(person)
    @person = person
  end

  def run
    minimize

    @person.minimized_at = Time.zone.now
    @person.save!
  end

  def minimize
    # noop - override in wagon
  end

end
