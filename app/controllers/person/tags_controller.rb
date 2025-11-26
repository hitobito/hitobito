# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::TagsController < TaggableController
  before_action :load_group, :load_person

  decorates :group, :person

  private

  def entry
    @person
  end

  def entry_path
    group_person_path(@group, @person)
  end

  def available_tags(query)
    super.where.not(name: excluded_tags)
  end

  def excluded_tags
    PersonTags::Validation.tag_names
  end

  def load_group
    @group = Group.find(params[:group_id])
  end

  def load_person
    @person = Person.find(params[:person_id])
  end
end
