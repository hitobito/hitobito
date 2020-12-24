# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupSettingsController < ModalCrudController

  skip_authorize_resource
  before_action :authorize_class, except: [:index]

  self.nesting = Group

  private

  alias group parent

  def self.model_class
    RailsSettings::Group
  end

  def entries
    model_class.list
  end

  def authorize_class
    authorize!(:update, parent)
  end

  def entry
    @group_setting ||= group.setting_objects.find_or_initialize_by(var: setting_id)
  end

  def setting_id
    params[:id]
  end

  def assign_attributes
    attrs = model_class.settings[setting_id]
    attrs.each do |a|
      value = model_params[a]
      entry.send("#{a}=", value)
    end
  end

  alias group_rails_settings_setting_object_url group_settings_url

end
