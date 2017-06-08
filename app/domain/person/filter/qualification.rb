# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Qualification < Person::Filter::Base

  self.required_ability = :full
  self.permitted_args = [:qualification_kind_ids, :validity]

  def initialize(attr, args)
    super
    id_list(:qualification_kind_ids)
  end

  def apply(scope)
    scope = scope.
            joins(:qualifications).
            where(qualifications: { qualification_kind_id: args[:qualification_kind_ids] })

    case args[:validity].to_s
    when 'active' then scope.merge(Qualification.active)
    when 'reactivateable' then scope.merge(Qualification.reactivateable)
    else scope
    end
  end

  def blank?
    args[:qualification_kind_ids].blank?
  end

  def to_params
    args.dup.tap do |hash|
      hash[:qualification_kind_ids] = hash[:qualification_kind_ids].join(ID_URL_SEPARATOR)
    end
  end

end
