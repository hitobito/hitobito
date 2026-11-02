# frozen_string_literal: true

#
#  Copyright (c) 2022-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::TotpResetController < ApplicationController
  def create
    authorize!(:totp_reset, person)
    authenticator.reset!
    redirect_to new_users_second_factor_path(second_factor: "totp")
  end

  def person
    @person ||= Person.find(params[:id])
  end

  def authenticator
    @authenticator ||= Authenticatable::TwoFactors::Totp.new(person,
      session)
  end
end
