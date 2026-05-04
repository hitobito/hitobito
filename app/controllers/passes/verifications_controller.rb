# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Passes::VerificationsController < ApplicationController
  skip_authorization_check
  layout false

  # Public endpoint for verifying a pass via QR code scan.
  # Accessible without authentication so that anyone (e.g. event staff)
  # can scan and verify a pass without needing a hitobito account.
  def show # rubocop:disable Metrics/CyclomaticComplexity
    @pass = Pass.find_by(verify_token: params[:verify_token])&.decorate
    @person = @pass&.person
    @definition = @pass&.pass_definition
    @group = @definition&.owner&.decorate
    @template = @definition&.template
    @state = pass_state
  end

  private

  # This controller will always be public
  def authenticate? = false

  def pass_state
    return :invalid unless @pass
    return :valid if @pass.active?
    return :expired if @pass.ended?

    :invalid
  end
end
