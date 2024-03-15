# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module ViewHelpers
  extend ActiveSupport::Concern

  class_methods do
    # Call to modify view paths for the following examples.
    # This can be used to add views only for the tests (e.g. in the spec/support dir).
    # It is implemented as an around hook and must be called outside examples.
    def prepend_view_path(view_path)
      around do |example|
        original_view_paths = ActionController::Base.view_paths
        ActionController::Base.prepend_view_path(view_path)
        example.run
        ActionController::Base.view_paths = original_view_paths
      end
    end
  end
end
