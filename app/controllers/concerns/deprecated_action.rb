# frozen_string_literal: true

#  Copyright (c) 2022-2023, Puzzle ITC GmbH. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module DeprecatedAction
  def deprecated_action
    send_deprecation("#{controller_path}##{action_name} was called unexpectedly.")
  end

  private

  def send_deprecation(err)
    Raven.capture_exception(ActiveSupport::DeprecationException.new(err), logger: "deprecation")
  end
end
