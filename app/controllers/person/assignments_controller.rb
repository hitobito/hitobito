# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AssignmentsController < CrudController

  private

  def authorize_class
    authorize!(:show_full, person)
  end

  def list_entries
    Assignment.list.where(person: person)
  end

  def person
    @person ||= group.people.find(params[:person_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end
end
