#  Copyright (c) 2012-2024, Schweizerischer Kanu-Verband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Membership::VerifyController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_authorization_check

  LEGACY_PASS_DEFINITION_ID = 1

  def show
    return head :not_found unless feature_enabled?

    verify_token = find_legacy_pass&.verify_token || "not-found"
    redirect_to pass_verify_path(verify_token), status: :found
  end

  private

  def find_legacy_pass
    Pass
      .joins(:person, :pass_definition)
      .find_by(
        pass_definition_id: LEGACY_PASS_DEFINITION_ID,
        people: {membership_verify_token: params[:verify_token]}
      )
  end

  def feature_enabled?
    People::Membership::Verifier.enabled?
  end
end
