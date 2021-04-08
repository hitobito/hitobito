# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FilteredList

  def initialize(user, params = {})
    @user = user
    @params = params
  end

  def entries
    @entries ||= fetch_entries.to_a
  end

  private

  def chain_scopes(scope, *filters)
    filters.inject(scope) do |result, filter|
      send(filter, result) || result
    end
  end

end
