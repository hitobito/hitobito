# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class QualificationsController < CrudController
  self.nesting = Group, Person

  self.permitted_attrs = [:qualification_kind_id, :qualification_kind, :start_at, :origin]

  decorates :group, :person

  # load parents before authorization
  prepend_before_action :parent

  before_render_form :load_qualification_kinds

  def create
    super(location: group_person_path(@group, @person))
  end

  def destroy
    super(location: group_person_path(@group, @person))
  end

  private

  def build_entry
    @person.qualifications.build
  end

  def load_qualification_kinds
    @qualification_kinds = QualificationKind.without_deleted.list
  end
end
