class Webauthn::Credentials::ChallengesController < ApplicationController
  skip_authorization_check

  def create
    # Generate WebAuthn ID if the user does not have any yet
    current_user.update(webauthn_id: WebAuthn.generate_user_id) unless current_user.webauthn_id

    # Prepare the needed data for a challenge
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_id,
        display_name: current_user.email, # we have only the email
        name: current_user.email # we have only the email
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id)
    )

    # Generate the challenge and save it into the session
    session[:webauthn_credential_register_challenge] = create_options.challenge

    respond_to do |format|
      format.json { render json: create_options }
    end
  end
end
