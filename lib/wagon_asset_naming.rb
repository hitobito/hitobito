# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Picks the one wagon whose name labels this boot's dev-only asset URL
# prefix and JS/CSS output directory (config/initializers/assets.rb,
# lib/tasks/assets.rake) - shared so the two can never drift apart, which
# would have Propshaft serve one wagon's assets under another wagon's
# prefix.
module WagonAssetNaming
  # youth/tenants are add-on wagons that ride along with a "real" customer
  # wagon and never own branded assets of their own, so they're excluded
  # when picking the one wagon that names the folder/prefix.
  SECONDARY_WAGONS = %w[youth tenants].freeze

  def self.primary_wagon_name
    (Wagons.all.map(&:wagon_name) - SECONDARY_WAGONS).first
  end
end
