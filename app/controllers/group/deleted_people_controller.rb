# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::DeletedPeopleController < CrudController

  decorates :group, :person

  helper_method :index_full_ability?

  def index
    respond_to do |format|
      format.html  { @people = Kaminari.paginate_array(PersonDecorator.decorate_collection(deleted_people)).page(params[:page]); @all_count = deleted_people.count }
    end
  end

  private

  def find_entry
    Person.find(params[:id]).decorate
  end

  def path_args(last)
    [Group.first, find_entry]
  end

  def model_class
    Person
  end

  def deleted_people
    @deleted_people ||= Group::DeletedPeople.deleted_for(group)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def index_full_ability?
    if params[:kind].blank?
      can?(:index_full_people, @group)
    else
      can?(:index_deep_full_people, @group)
    end
  end
end
