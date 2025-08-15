# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::AddressesSyncsController < ApplicationController
  def create
    group = Group.find(params[:group_id])
    authorize!(:sync_addresses, group)

    if AddressSynchronizationJob.exists?
      redirect_to group_path(group), alert: flash_message(:running)
    else
      AddressSynchronizationJob.new.enqueue!
      redirect_to group_path(group), notice: flash_message(:scheduled)
    end
  end

  private

  def flash_message(message)
    t("people.addresses_sync.create.#{message}")
  end
end
