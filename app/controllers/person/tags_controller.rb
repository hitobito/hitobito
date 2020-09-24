# frozen_string_literal: true

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
    create_tag(permitted_params[:name])
    @tags = person_tags

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # create.js.haml
    end
  end

  def destroy
    authorize!(:manage_tags, @person)
    @person.tags.find_by(name: params[:name]).try(:destroy!)

    respond_to do |format|
      format.html { redirect_to group_person_path(@group, @person) }
      format.js # destroy.js.haml
    end
  end

  private

  def person_tags
    @person
      .reload
      .tags
      .order(:name)
      .grouped_by_category
  end

  def create_tag(name)
    ActsAsTaggableOn::Tagging.find_or_create_by!(
      taggable: @person,
      tag: ActsAsTaggableOn::Tag.find_or_create_by(name: name),
      context: 'tags'
    )
  end

  def permitted_params
    params.require(:acts_as_taggable_on_tag).permit(permitted_attrs)
  end

  def available_tags(query)
    Person
      .tags_on(:tags)
      .where('name LIKE ?', "%#{query}%")
      .where.not(name: excluded_tags)
      .order(:name)
      .limit(10)
      .pluck(:name)
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
