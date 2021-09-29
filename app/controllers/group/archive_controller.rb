# frozen_string_literal: true

#  Copyright (c) 2021, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::ArchiveController < ApplicationController

  before_action :authorize_action

  def create
    ActiveRecord::Base.transaction do
      archival_timestamp = Time.zone.now

      archive_roles(archival_timestamp) and
        archive_group(archival_timestamp) and
        entry.save!
    end

    redirect_to group_path(entry), notice: I18n.t('group.archive.flash.success')
  end

  private

  def entry
    @entry ||= Group.find_by!(id: params[:id])
  end

  def authorize_action
    authorize!(:destroy, entry) # not exactly the same, but close enough
  end

  def archive_roles(archival_timestamp)
    Role.where(group_id: entry.id)
        .touch_all(:archived_at, time: archival_timestamp)
  end

  def archive_group(archival_timestamp)
    entry.archived_at = archival_timestamp
  end

end
