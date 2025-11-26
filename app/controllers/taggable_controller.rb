# frozen_string_literal: true

#  Copyright (c) 2025, SAC CAS. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class TaggableController < ApplicationController
  respond_to :html

  def query
    authorize!(:assign_tags, entry)
    render json: query_tags
  end

  def create
    authorize!(:assign_tags, entry)
    assign_tag

    respond_to do |format|
      format.html { redirect_to entry_path }
      format.js { @tags = entry_tags } # create.js.haml
    end
  end

  def destroy
    authorize!(:assign_tags, entry)
    entry.tag_list.remove(params[:name])
    entry.save!

    respond_to do |format|
      format.html { redirect_to entry_path }
      format.js # destroy.js.haml
    end
  end

  private

  def entry
    # implement in subclass
  end

  def entry_path
    # implement in subclass
  end

  def query_tags
    if params.key?(:q) && params[:q].size >= 3
      available_tags(params[:q]).pluck(:name).map { |tag| {label: tag} }
    else
      []
    end
  end

  def available_tags(query)
    ActsAsTaggableOn::Tag
      .where("name ILIKE ?", "%#{query}%")
      .order(:name)
      .limit(10)
  end

  def entry_tags
    entry
      .reload
      .tags
      .order(:name)
      .grouped_by_category
  end

  def assign_tag
    tag = find_or_create_tag
    return unless tag

    ActsAsTaggableOn::Tagging.find_or_create_by!(
      taggable: entry,
      tag:,
      context: "tags"
    )
  end

  def find_or_create_tag
    name = tag_name
    return if name.blank?

    tag = ActsAsTaggableOn::Tag.find_or_initialize_by(name: name.strip.gsub(/\s*:\s*/, ":"))
    if tag.new_record?
      authorize!(:create_tags, entry)
      tag.save!
    end
    tag
  end

  def tag_name
    params.dig(:acts_as_taggable_on_tag, :name)
  end
end
