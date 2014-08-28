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

    preload_association(records, :roles)

    roles = records.collect { |record| record.roles }.flatten
    preload_association(roles, :group, Group.select(Group::MINIMAL_SELECT))

    preload_groups_manually(records)

    records
  end

  def do_preload_groups
    @do_preload_groups = true
  end

  private

  def self.preload_association(records, association, scope = nil)
    ActiveRecord::Associations::Preloader.new.
      preload(records, association, scope)
  end

  def self.preload_groups_manually(records)
    # preload groups manually because rails would
    # empty the through association (=roles) again.
    if records.present? && !records.first.association(:groups).loaded?
      records.each do |person|
        groups = person.roles.collect(&:group).flatten.compact

        association = person.association(:groups)
        association.loaded!
        association.target.concat(groups)
        groups.each { |g| association.set_inverse_instance(g) }
      end
    end
  end

  def exec_queries
    records = super

    Person::PreloadGroups.for(records) if @do_preload_groups

    records
  end

end
