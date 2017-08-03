# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::TagsController < ApplicationController

  class_attribute :permitted_attrs

  before_action :load_group
  before_action :load_person

  decorates :group, :person

  respond_to :html

  self.permitted_attrs = [:name]

  def query
    authorize!(:index_tags, @person)
    tags = []

    if params.key?(:q) && params[:q].size >= 3
      tags = available_tags(params[:q]).map { |tag| { label: tag } }
    end

    render json: tags
  end

  def create
    authorize!(:manage_tags, @person)
    @person.tag_list.add(permitted_params[:name], parse: true)
    @person.save!
    @tags = @person.reload.tags.grouped_by_category

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # create.js.haml
    end
  end

  def destroy
    authorize!(:manage_tags, @person)
    @person.tag_list.remove(params[:name])
    @person.save!

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # destroy.js.haml
    end
  end

  private

  def permitted_params
    params.require(:acts_as_taggable_on_tag).permit(permitted_attrs)
  end

  def available_tags(q)
    Person.tags_on(:tags)
      .where('name LIKE ?', "%#{q}%")
      .order(:name)
      .limit(10)
      .pluck(:name)
  end

  def load_group
    @group = Group.find(params[:group_id])
  end

  def load_person
    @person = Person.find(params[:person_id])
  end

end
