# encoding: utf-8

#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::SubgroupsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:group]

  def initialize(user_id, group, options)
    super(:csv, user_id, options)
    @exporter = Export::Tabular::Groups::List
    @group = group
  end

  private

  def entries
    @group.self_and_descendants
          .without_deleted
          .order(:lft)
          .includes(:contact)
  end
end
