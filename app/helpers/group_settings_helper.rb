# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module GroupSettingsHelper

  def group_setting_form_params
    { url: group_group_setting_path(group: @group, id: entry.var),
      method: :patch }
  end

end
