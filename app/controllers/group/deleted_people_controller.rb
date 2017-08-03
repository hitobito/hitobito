# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::DeletedPeopleController < ListController

  before_action :authorize_action

  self.nesting = Group

  decorates :people, :group

  private

  def group
    parent
  end

  def model_class
    Person
  end

  def list_entries
    Group::DeletedPeople.deleted_for(group).
      includes(:additional_emails, :phone_numbers).
      order_by_name.
      page(params[:page])
  end

  def authorize_action
    authorize!(:index_deleted_people, group)
  end
end
