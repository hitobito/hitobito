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
    @qualification_kind_ids = Array(params[:qualification_kind_id])
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
    scope = scope.joins(:qualifications).
                  where(qualifications: { qualification_kind_id: qualification_kind_ids })

    case validity
    when 'active' then scope.merge(Qualification.active)
    when 'reactivateable' then scope.merge(Qualification.reactivateable)
    else scope
    end
  end

end
