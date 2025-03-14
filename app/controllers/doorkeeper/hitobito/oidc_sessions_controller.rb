# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Doorkeeper::Hitobito::OidcSessionsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def destroy
    if id_token
      reset_session
      sessions.destroy_all
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

  def sessions = Session.where(person_id: id_token[:sub])

  def access_tokens
    Oauth::AccessToken.active.joins(:application)
      .where(resource_owner_id: id_token[:sub], application: {uid: id_token[:aud]})
  end

  def decode_id_token
    return if params[:id_token_hint].blank?

    config = Doorkeeper::OpenidConnect.configuration
    public_key = OpenSSL::PKey.read(config.signing_key).public_key
    algorithm = config.signing_algorithm.upcase.to_s
    validate_signature = false
    # FIXME - start validating and handling signatures errors
    JWT.decode(params[:id_token_hint], public_key, validate_signature, {algorithm: algorithm})[0]
  end

  def redirect_target
    URI.parse(params[:post_logout_redirect_uri].presence || new_person_session_url(oauth: true)).tap do |uri|
      query = CGI.parse(uri.query.to_s).symbolize_keys.merge(params.to_unsafe_h.slice(:state))
      uri.query = URI.encode_www_form(query) if query.present?
    end
  end
end
