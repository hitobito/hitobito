# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Paranoia
  module RegularScope

    # Do not exclude deleted entries in default scope.
    # Benefit: When an association references a deleted entry,
    # this entry is still found and may be displayed.
    # Tradeoff: When choosing an associated entry, the scope
    # :without_deleted has to specified explicitly.
    def default_scope
      with_deleted
    end

    def without_deleted
      where(deleted_at: nil)
    end

  end
end
