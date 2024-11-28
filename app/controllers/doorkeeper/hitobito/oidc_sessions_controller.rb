# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Doorkeeper::Hitobito::OidcSessionsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def destroy
    if id_token
      reset_session
      access_tokens.destroy_all
      redirect_to redirect_target, allow_other_host: true, notice: I18n.t("devise.sessions.signed_out")
    else
      render plain: "failed to process token", status: :unprocessable_entity
    end
  end

  private

  def id_token
    @id_token ||= decode_id_token&.symbolize_keys
  end

  def access_tokens
    Oauth::AccessToken.active.joins(:application)
      .where(resource_owner_id: id_token[:sub], application: {uid: id_token[:aud]})
  end

  def decode_id_token
    return if params[:id_token_hint].blank?

    config = Doorkeeper::OpenidConnect.configuration
    public_key = OpenSSL::PKey.read(config.signing_key).public_key
    algorithm = config.signing_algorithm.upcase.to_s
    JWT.decode(params[:id_token_hint], public_key, false, {algorithm: algorithm})[0]
  rescue JWT::ExpiredSignature => e
    JWT.decode(id_token, nil, false)[0].tap do |token|
      Airbrake.notify(e, token[0])
    end
  end

  def redirect_target
    params[:post_logout_redirect_uri].presence || new_person_session_url(oauth: true)
  end
end
