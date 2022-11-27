# frozen_string_literal: true

#  Copyright (c) 2021, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::ArchiveController < ApplicationController

  before_action :authorize_action

  def create
    entry.archive!

    redirect_to group_path(entry), notice: I18n.t('group.archive.flash.success')
  end

  private

  def entry
    @entry ||= Group.find_by!(id: params[:id])
  end

  def authorize_action
    authorize!(:destroy, entry) # not exactly the same, but close enough
  end

end
