#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sentry
  extend ActiveSupport::Concern

  included do
    before_action :set_sentry_request_context
    before_action :set_sentry_user_context
  end

  def set_sentry_request_context
    Raven.extra_context(params: params.dup.to_unsafe_h, url: request.url)
  end

  def set_sentry_user_context
    Raven.user_context(id: current_user.try(:id), name: current_user.try(:email))
  end
end
