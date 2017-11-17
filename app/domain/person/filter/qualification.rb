# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Qualification < Person::Filter::Base

  self.required_ability = :full
  self.permitted_args = [:qualification_kind_ids, :validity, :match,
                         :start_at_year_from, :start_at_year_until,
                         :finish_at_year_from, :finish_at_year_until]

  def initialize(attr, args)
    super
    id_list(:qualification_kind_ids)
  end

  def apply(scope)
    scope = scope.joins(:roles) if sort_by_role?
    if args[:match].to_s == 'all'
      match_all_qualification_kinds(scope)
    else
      match_one_qualification_kind(scope)
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

  private

  def match_all_qualification_kinds(scope)
    subquery = qualification_scope(scope).
               select('1').
               where('qualifications.person_id = people.id AND ' \
                       'qualifications.qualification_kind_id = qk.id')

    scope.where('NOT EXISTS (' \
                '  SELECT 1 FROM qualification_kinds qk' \
                '  WHERE qk.id IN (?) ' \
                "  AND NOT EXISTS (#{subquery.to_sql}) )",
                args[:qualification_kind_ids])
  end

  def match_one_qualification_kind(scope)
    scope.
      joins(:qualifications).
      where(qualifications: { qualification_kind_id: args[:qualification_kind_ids] }).
      merge(qualification_scope(scope))
  end

  def qualification_scope(scope)
    qualification_validity_scope(scope)
      .merge(start_scope)
      .merge(finish_scope)
  end

  def finish_scope
    qualification_date_year_scope(
      :finish_at,
      args[:finish_at_year_from],
      args[:finish_at_year_until]
    )
  end

  def start_scope
    qualification_date_year_scope(
      :start_at,
      args[:start_at_year_from],
      args[:start_at_year_until]
    )
  end

  def qualification_date_year_scope(attr, from, untils)
    scope = ::Qualification.all
    scope = scope.where("#{attr} >= ?", Date.new(from, 1, 1)) if from.to_i > 0
    scope = scope.where("#{attr} <= ?", Date.new(untils, 12, 31)) if untils.to_i > 0
    scope
  end

  def qualification_validity_scope(_scope)
    case args[:validity].to_s
    when 'active'         then ::Qualification.active
    when 'reactivateable' then ::Qualification.reactivateable
    else ::Qualification.all
    end
  end

  def sort_by_role?
    Settings.people.default_sort == 'role'
  end

end
