class Webauthn::AuthenticationsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    user = User.find_by(id: session.dig(:webauthn_authentication, "user_id"))

    if user
      render :index, locals: {
        user: user
      }
    else
      redirect_to new_user_session_path, error: "Authentication error"
    end
  end

  def create
    # prepare needed data
    webauthn_credential = WebAuthn::Credential.from_get(params)
    user = User.find(session[:webauthn_authentication]["user_id"])
    credential = user.webauthn_credentials.find_by(external_id: webauthn_credential.id)

    begin
      # verification
      webauthn_credential.verify(
        session[:webauthn_authentication]["challenge"],
        public_key: credential.public_key,
        sign_count: credential.sign_count
      )

      # update the sign count
      credential.update!(sign_count: webauthn_credential.sign_count)

      # signing the user in manually
      sign_in(:user, user)

      # set the remember me - I hope this is working solution :)
      user.remember_me! if session[:webauthn_authentication]["remember_me"]

      # set the redirect URL
      redirect = stored_location_for(user) || root_url

      # you can use flash messages here
      flash[:notice] = "Hey, welcome back!"

      render json: {redirect: redirect}, status: :ok
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:webauthn_authentication)
    end
  end
end
