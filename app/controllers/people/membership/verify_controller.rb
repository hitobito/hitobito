#  Copyright (c) 2012-2024, Schweizerischer Kanu-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Membership::VerifyController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_authorization_check

  def show
    verify_token = find_legacy_pass&.verify_token || "not-found"
    redirect_to pass_verify_path(verify_token), status: :found
  end

  private

  def find_legacy_pass
    pass_definition_id = Settings.passes&.membership_pass_definition_id
    Pass
      .joins(:person, :pass_definition)
      .find_by(
        people: {membership_verify_token: params[:verify_token]},
        pass_definition_id:
      )
  end
end
