# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

module SessionsHelper
  def render_self_registration_title(group)
    group.custom_self_registration_title.presence ||
      t('groups/self_registration.new.title', group_name: group.name)
  end

  def render_self_registration_link
    return unless FeatureGate.enabled?('groups.self_registration')

    group = Group.find_by(main_self_registration_group: true)
    if group&.self_registration_active?
      link_to t('layouts.unauthorized.main_self_registration'),
              group_self_registration_path(group_id: group.id)
    end
  end
end
