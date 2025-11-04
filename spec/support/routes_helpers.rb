# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module RoutesHelpers
  def draw_test_routes(&block)
    Rails.application.routes.send(:eval_block, block)
    @routes_modified = true
  end

  def self.included(base)
    base.after do
      Rails.application.reload_routes! if @routes_modified
    end
  end
end
