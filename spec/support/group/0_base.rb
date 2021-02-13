#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# no wagons loaded
if ENV["APP_ROOT"].blank? || ENV["RAILS_USE_TEST_GROUPS"]
  Group.reset_types!

  # global roles and children
  require Rails.root.join("spec/support/group/external_role.rb")
  Group.roles Role::External

  require Rails.root.join("spec/support/group/global_group.rb")
  Group.children Group::GlobalGroup

  require Rails.root.join("spec/support/group/top_layer.rb")
  Group.root_types Group::TopLayer
end
