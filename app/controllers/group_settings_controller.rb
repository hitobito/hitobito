# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupSettingsController < ModalCrudController

  skip_authorize_resource
  before_action :authorize_class

  self.nesting = Group

  decorates :setting_objects

  private

  alias group parent

  def list_entries
    group.settings_all
  end

  def authorize_class
    authorize!(:update, group)
  end

  def entry
    @group_setting ||= fetch_entry
  end

  def fetch_entry
    raise ActiveRecord::RecordNotFound unless GroupSetting::SETTINGS.keys.include?(setting_id)

    entry = group.setting_objects.find_or_initialize_by(var: setting_id)
    entry.becomes(GroupSetting).decorate
  end

  def setting_id
    params[:id]
  end

  def return_path
    group_group_settings_path(group: @group)
  end

  def assign_attributes
    entry.attrs.each do |a|
      value = model_params[a]
      # set password only if value provided
      next if a.eql?(:password) && value.blank?

      entry.send("#{a}=", value)
    end
  end

end
