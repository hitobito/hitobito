# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

# Our error tracker (sentry-raven) is deprecated and no longer captures rails application errors reliably.
# We piggy-back on ActionDispatch::ShowExceptions middleware and copy the exception to a key, where sentry-raven expects it.
class Raven::CopyException
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env).tap do
      env["rack.exception"] = env["action_dispatch.exception"]
    end
  end
end
