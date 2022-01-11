# frozen_string_literal: true
#
#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::TotpDisableController < ApplicationController

  def create
    authorize!(:totp_disable, person)
    authenticator.disable!
    redirect_to group_person_path(group, person), notice: t('.flashes.success')
  end

  def person
    @person ||= Person.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authenticator
    @authenticator ||= Authenticatable::SecondFactors::Totp.new(person,
                                                                session)
  end
end
