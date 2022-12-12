# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrailed
  extend ActiveSupport::Concern

  included do
    before_action :set_paper_trail_whodunnit
  end

  private

  def user_for_paper_trail
    if current_user.present?
      origin_user_id = session[:origin_user]
      origin_user_id ? origin_user_id : super
    else
      user_for_paper_trail_api_sign_in
    end
  end

  def user_for_paper_trail_api_sign_in
    if current_service_token
      type = ServiceToken.sti_name
      ::PaperTrail.request.controller_info = { whodunnit_type: type }
      return current_service_token.id
    end

    oauth_token_user&.id
  end

end
