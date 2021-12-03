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

  def year_scope?
    %w(start_at finish_at).product(%w(year_from year_until)).any? do |pre, post|
      key = [pre, post].join('_')
      args[key.to_sym].present? || args[key].present?
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
    scope = qualification_validity_scope(scope)
    return scope unless year_scope?

    scope.
      where(id: grouped_most_recent_qualifications_ids).
      merge(start_scope).
      merge(finish_scope)
  end

  def grouped_most_recent_qualifications_ids
    Qualification.
      group(:person_id, :qualification_kind_id).select('max(id)').
      where(qualification_kind_id: args[:qualification_kind_ids])
  end

  def finish_scope
    qualification_date_year_scope(:finish_at)
  end

  def start_scope
    qualification_date_year_scope(:start_at)
  end

  def qualification_date_year_scope(attr)
    from = args[:"#{attr}_year_from"].to_i
    untils = args["#{attr}_year_until"].to_i

    scope = ::Qualification.all
    scope = scope.where(Qualification.arel_table[attr].gteq(Date.new(from, 1, 1))) if from > 0
    scope = scope.where(Qualification.arel_table[attr].lteq(Date.new(untils, 12, 31))) if untils > 0
    scope
  end

  def qualification_validity_scope(_scope)
    case args[:validity].to_s
    when 'active'         then ::Qualification.active
    when 'reactivateable' then ::Qualification.reactivateable
    else ::Qualification.all
    end
  end

end
