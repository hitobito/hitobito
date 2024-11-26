# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Doorkeeper::Hitobito::OidcSessionsController < ::Doorkeeper::ApplicationMetalController
  before_action -> { doorkeeper_authorize! :openid }

  def destroy
    doorkeeper_token.destroy!
    reset_session
    redirect_target = params[:post_logout_redirect_uri].presence || new_person_session_url(oauth: true)

    redirect_to URI.parse(redirect_target).to_s, notice: I18n.t("devise.sessions.signed_out")
  end
end
