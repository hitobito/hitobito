# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizerischer Kanu-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Membership::VerifyController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_authorization_check

  def show
    person = Person.find_by(membership_verify_token: params[:verify_token])
    pass_definition = legacy_pass_definition

    pass = Pass.find_by(person:, pass_definition:) if person && pass_definition
    verify_token = pass&.verify_token || "not-found"

    redirect_to pass_verify_path(verify_token), status: :found
  end

  private

  def legacy_pass_definition
    key = Settings.passes&.legacy_verify_pass_definition_key
    PassDefinition.find_by(template_key: key) if key.present?
  end
end
