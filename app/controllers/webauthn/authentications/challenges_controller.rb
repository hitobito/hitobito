class Webauthn::Authentications::ChallengesController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    user = if params.dig(:user, :email)
      # passwordless
      User.find_by(email: params[:user][:email])
    else
      # 2fa
      User.find_by(id: session[:webauthn_authentication]["user_id"])
    end

    if user
      # prepare WebAuthn options
      get_options = WebAuthn::Credential.options_for_get(allow: user.webauthn_credentials.pluck(:external_id))

      # prepare session for passwordless
      session[:webauthn_authentication] ||= {}
      unless session[:webauthn_authentication]["user_id"]
        session[:webauthn_authentication]["user_id"] = user.id
        session[:webauthn_authentication]["remember_me"] = params.dig(:user, :remember_me) == "1"
      end

      # save the challenge
      session[:webauthn_authentication]["challenge"] = get_options.challenge

      respond_to do |format|
        format.json { render json: get_options }
      end
    else
      respond_to do |format|
        format.json { render json: {message: "Authentication failed"}, status: :unprocessable_entity }
      end
    end
  end
end
