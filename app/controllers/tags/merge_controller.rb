# frozen_string_literal: true

class Tags::MergeController < ApplicationController

  before_action :authorize

  def new
    @name = dst_tag.name
    @src_tag_ids = src_tag_ids
    @tag_names = tag_names
  end

  def create
    merger.merge!

    redirect_to tags_path, notice: translate('success')
  end

  private

  def tag_names
    tags.collect(&:name).join(', ')
  end

  def src_tag_ids
    tag_ids = tags.collect(&:id)
    tag_ids.delete(dst_tag.id)
    tag_ids
  end

  def dst_tag
    @dst_tag ||= tags.last
  end

  def tags
    @tags ||= ActsAsTaggableOn::Tag.where(id: list_param(:ids)).order(:taggings_count)
  end

  def merger
    Tags::Merger.new(list_param(:src_tag_ids, :tags_merge),
                     merge_params[:dst_tag_id],
                     merge_params[:name])
  end

  def merge_params
    params[:tags_merge]
  end

  def authorize
    authorize!(:edit, ActsAsTaggableOn::Tag)
  end
end
