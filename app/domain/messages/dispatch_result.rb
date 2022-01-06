# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class DispatchResult < Struct.new(:name)
    %i[finished needs_reenqueue finishes_asynchronously].each do |result|
      define_singleton_method(result) do
        DispatchResult.new(result)
      end

      define_method(:"#{result}?") do
        name == result
      end
    end
  end
end