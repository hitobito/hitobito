# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class Person::TagsController < ApplicationController

  class_attribute :permitted_attrs

  # authorize_resource except: :query

  decorates :group, :person

  respond_to :html

  self.permitted_attrs = [:name]

  def query
    load_group_and_person
    authorize!(:index_tags, @person)
    tags = []

    if params.key?(:q) && params[:q].size >= 3
      tags = available_tags(params[:q]).map { |tag| { label: tag } }
    end

    render json: tags
  end

  def create
    load_group_and_person
    authorize!(:create, @person.tags.new)
    @tag = @person.tags.create(name: permitted_params[:name])

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # create.js.haml
    end
  end

  def destroy
    load_group_and_person
    @tag = @person.tags.find(params[:id]).destroy
    authorize!(:destroy, @tag)

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # destroy.js.haml
    end
  end

  private

  def permitted_params
    params.require(:tag).permit(permitted_attrs)
  end

  def available_tags(q)
    Tag.
      where.not(name: @person.tags.map(&:name)).
      where('name LIKE ?', "%#{q}%").
      select(:name).
      order(:name).
      distinct.
      limit(10).
      pluck(:name)
  end

  def load_group_and_person
    @group = Group.find(params[:group_id])
    @person = Person.find(params[:person_id])
  end

end
