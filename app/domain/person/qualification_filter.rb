# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QualificationFilter < Person::ListFilter

  self.accessibles_class = PersonFullReadables

  attr_reader :kind, :validity, :qualification_kind_ids

  def initialize(group, user, params)
    super(group, user)
    @kind = params[:kind].to_s
    @validity = params[:validity].to_s
    @match_all = params[:match].to_s == 'all'
    @qualification_kind_ids = Array(params[:qualification_kind_id])
    @start_at_year_from = params[:start_at_year_from].presence.to_i
    @start_at_year_until = params[:start_at_year_until].presence.to_i
    @finish_at_year_from = params[:finish_at_year_from].presence.to_i
    @finish_at_year_until = params[:finish_at_year_until].presence.to_i
  end

  private

  def filtered_entries(&block)
    if qualification_kind_ids.present?
      entries_with_qualifications(list_scope(kind, &block))
    else
      unfiltered_entries(&block)
    end
  end

  def entries_with_qualifications(scope)
    if @match_all
      match_all_qualification_kinds(scope)
    else
      match_one_qualification_kind(scope)
    end
  end

  def match_all_qualification_kinds(scope)
    subquery = qualification_scope.
               select('1').
               where('qualifications.person_id = people.id AND ' \
                       'qualifications.qualification_kind_id = qk.id')

    scope.where('NOT EXISTS (' \
                '  SELECT 1 FROM qualification_kinds qk' \
                '  WHERE qk.id IN (?) ' \
                "  AND NOT EXISTS (#{subquery.to_sql}) )",
                qualification_kind_ids)
  end

  def match_one_qualification_kind(scope)
    scope.joins(:qualifications).
      where(qualifications: { qualification_kind_id: qualification_kind_ids }).
      merge(qualification_scope)
  end

  def qualification_scope
    qualification_validity_scope.
      merge(qualification_date_year_scope(:start_at, @start_at_year_from, @start_at_year_until)).
      merge(qualification_date_year_scope(:finish_at, @finish_at_year_from, @finish_at_year_until))
  end

  def qualification_validity_scope
    case validity
    when 'active' then Qualification.active
    when 'reactivateable' then Qualification.reactivateable
    else Qualification.all
    end
  end

  def qualification_date_year_scope(attr, from, untils)
    scope = Qualification.all
    scope = scope.where("#{attr} >= ?", Date.new(from, 1, 1)) if from > 0
    scope = scope.where("#{attr} <= ?", Date.new(untils, 12, 31)) if untils > 0
    scope
  end

end
