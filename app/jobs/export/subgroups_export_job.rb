# encoding: utf-8

#  Copyright (c) 2018-2019, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::SubgroupsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:group_id]

  def initialize(user_id, group_id, options)
    super(:csv, user_id, options)
    @exporter = Export::Tabular::Groups::List
    @group_id = group_id
  end

  private

  def entries
    group.self_and_descendants
         .without_deleted
         .order(:lft)
         .includes(:contact)
  end

  def group
    @group ||= Group.find(@group_id)
  end
end
