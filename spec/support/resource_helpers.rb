#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

module ResourceHelpers
  extend ActiveSupport::Concern

  included do
    before do
      allow(graphiti_context).to receive(:can?).and_return(true)
    end
  end
end
