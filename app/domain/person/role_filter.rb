# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::RoleFilter < Person::ListFilter

  attr_reader :kind, :filter

  def initialize(group, user, params)
    super(group, user)
    @kind = params[:kind].to_s
    @filter = PeopleFilter.new(role_type_ids: params[:role_type_ids])
  end

  private

  def filtered_entries(&block)
    if filter.role_types.present?
      list_scope(kind, &block).where(roles: { type: filter.role_types })
    else
      unfiltered_entries(&block)
    end
  end

end
