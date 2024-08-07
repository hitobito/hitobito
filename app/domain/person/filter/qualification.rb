#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Qualification < Person::Filter::Base
  self.required_ability = :full
  self.permitted_args = [:qualification_kind_ids, :validity, :match, :reference_date,
    :start_at_year_from, :start_at_year_until,
    :finish_at_year_from, :finish_at_year_until]

  def initialize(attr, args)
    super
    id_list(:qualification_kind_ids)
  end

  def apply(scope)
    if args[:validity].to_s == "not_active"
      no_active_qualification_scope(scope)
    elsif args[:validity].to_s == "none"
      no_qualification_scope(scope)
    elsif args[:validity].to_s == "only_expired"
      only_expired_qualification_scope(scope)
    elsif args[:match].to_s == "all"
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
    args[:validity].to_s == "all" &&
      %w[start_at finish_at].product(%w[year_from year_until]).any? do |pre, post|
        key = [pre, post].join("_")
        args[key.to_sym].present? || args[key].present?
      end
  end

  private

  def match_all_qualification_kinds(scope)
    subquery = qualification_scope(scope)
      .select("1")
      .where("qualifications.person_id = people.id AND " \
                       "qualifications.qualification_kind_id = qk.id")

    scope.where("NOT EXISTS (" \
                "  SELECT 1 FROM qualification_kinds qk" \
                "  WHERE qk.id IN (?) " \
                "  AND NOT EXISTS (#{subquery.to_sql}) )",
      args[:qualification_kind_ids])
  end

  def match_one_qualification_kind(scope)
    scope
      .joins(:qualifications)
      .where(qualifications: {qualification_kind_id: args[:qualification_kind_ids]})
      .merge(qualification_scope(scope))
  end

  def no_active_qualification_scope(scope)
    scope
      .left_joins(:qualifications)
      .merge(::Qualification.not_active(args[:qualification_kind_ids], reference_date))
  end

  def only_expired_qualification_scope(scope)
    scope
      .joins(:qualifications)
      .merge(::Qualification.only_expired(args[:qualification_kind_ids], reference_date))
  end

  def no_qualification_scope(scope)
    kind_ids = args[:qualification_kind_ids].map(&:to_i).join(",").presence
    joined = scope.left_joins(:qualifications) unless kind_ids
    joined ||= scope.joins <<~SQL
      LEFT OUTER JOIN qualifications ON qualifications.person_id = people.id
      AND qualifications.qualification_kind_id IN (#{kind_ids})
    SQL
    joined.where(qualifications: {id: nil})
  end

  def qualification_scope(scope)
    scope = qualification_validity_scope(scope)
    return scope unless year_scope?

    scope
      .where(id: grouped_most_recent_qualifications_ids)
      .merge(start_scope)
      .merge(finish_scope)
  end

  def grouped_most_recent_qualifications_ids
    Qualification
      .group(:person_id, :qualification_kind_id)
      .where(qualification_kind_id: args[:qualification_kind_ids])
      .select("max(id)")
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
    when "active" then ::Qualification.active(reference_date)
    when "reactivateable" then ::Qualification.reactivateable(reference_date)
    when "not_active_but_reactivateable" then not_active_but_reactivateable(reference_date)
    else ::Qualification.all
    end
  end

  def not_active_but_reactivateable(date)
    ::Qualification
      .not_active(args[:qualification_kind_ids], date)
      .only_reactivateable(date)
  end

  def reference_date
    return if args[:reference_date].blank?

    Date.parse(args[:reference_date])
  rescue ArgumentError
    nil
  end
end
