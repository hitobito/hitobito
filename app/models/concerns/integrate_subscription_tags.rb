# frozen_string_literal: true

#  Copyright (c) 2024-2024, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module IntegrateSubscriptionTags
  extend ActiveSupport::Concern

  included do
    has_many :subscription_tags, dependent: :destroy
  end
end
