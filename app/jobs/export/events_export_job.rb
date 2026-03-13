#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventsExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:group_id, :filter_args]

  def initialize(format, user_id, group_id, filter_args, options)
    super(format, user_id, options)
    @group_id = group_id
    @filter_args = filter_args
    @exporter = Export::Tabular::Events::List
  end

  private

  def filter
    @filter ||= Events::Filter::GroupList.new(group, user, @filter_args.with_indifferent_access)
  end

  def group
    @group ||= Group.find(@group_id)
  end

  def entries
    filter.entries
  end
end
