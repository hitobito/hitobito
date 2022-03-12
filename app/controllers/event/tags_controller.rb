# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::TagsController < ApplicationController

  class_attribute :permitted_attrs

  before_action :load_group
  before_action :load_event

  decorates :group, :event

  respond_to :html

  self.permitted_attrs = [:name]

  def query
    authorize!(:show, @event)
    tags = []

    if params.key?(:q) && params[:q].size >= 3
      tags = available_tags(params[:q]).map { |tag| { label: tag } }
    end

    render json: tags
  end

  def create
    authorize!(:update, @event)
    create_tag(permitted_params[:name])
    @tags = event_tags

    respond_to do |format|
      format.html { redirect_to group_event_path(@group, @event) }
      format.js # create.js.haml
    end
  end

  def destroy
    authorize!(:manage_tags, @event)
    @event.tag_list.remove(params[:name])
    @event.save!

    respond_to do |format|
      format.html { redirect_to group_event_path(@group, @event) }
      format.js # destroy.js.haml
    end
  end

  private

  def event_tags
    @event
      .reload
      .tags
      .order(:name)
      .grouped_by_category
  end

  def create_tag(name)
    return unless name.present?

    ActsAsTaggableOn::Tagging.find_or_create_by!(
      taggable: @event,
      tag: ActsAsTaggableOn::Tag.find_or_create_by(name: name),
      context: 'tags'
    )
  end

  def permitted_params
    params.require(:acts_as_taggable_on_tag).permit(permitted_attrs)
  end

  def available_tags(query)
    ActsAsTaggableOn::Tag
      .where('name LIKE ?', "%#{query}%")
      .where.not(name: excluded_tags)
      .order(:name)
      .limit(10)
      .pluck(:name)
  end

  def excluded_tags
    []
  end

  def load_group
    @group = Group.find(params[:group_id])
  end

  def load_event
    @event = Event.find(params[:event_id])
  end

end
