# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::PreloadGroups

  def self.extended(base)
    base.do_preload_groups
  end

  def self.for(records)
    records = Array(records)

    # preload roles
    ActiveRecord::Associations::Preloader.new(
      records,
      :roles).run

    # preload roles -> group
    ActiveRecord::Associations::Preloader.new(
      records.collect { |record| record.roles }.flatten,
      :group,
      select: Group::MINIMAL_SELECT).run

    # preload groups
    ActiveRecord::Associations::Preloader.new(
      records,
      :groups,
      select: Group::MINIMAL_SELECT).run

    records
  end

  def do_preload_groups
    @do_preload_groups = true
  end

  private

  def exec_queries
    records = super

    Person::PreloadGroups.for(records) if @do_preload_groups

    records
  end
end
