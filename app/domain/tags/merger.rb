# frozen_string_literal: true

class Tags::Merger

  def initialize(src_tag_ids, dst_tag_id, new_name)
    @src_tag_ids = src_tag_ids.reject do |s|
      validation_tag_ids.include?(s)
    end
    @dst_tag_id = dst_tag_id
    @new_name = new_name
  end

  def merge!
    return if @src_tag_ids.empty? || @src_tag_ids.include?(@dst_tag_id)

    ActsAsTaggableOn::Tag.transaction do
      taggings = collect_taggings
      destroy_src_tags
      if taggings.present?
        ActsAsTaggableOn::Tagging.insert_all!(taggings)
        ActsAsTaggableOn::Tag.reset_counters(@dst_tag_id, :taggings)
      end
      update_name
    end
  end

  private

  def dst_tag
    @dst_tag ||= ActsAsTaggableOn::Tag.find(@dst_tag_id)
  end

  def update_name
    @dst_tag.update!(name: @new_name) if update_name?
  end

  def update_name?
    @new_name.present? && dst_tag.name != @new_name
  end

  def destroy_src_tags
    ActsAsTaggableOn::Tag.where(id: @src_tag_ids).where.not(id: validation_tag_ids).destroy_all
  end

  def taggable_person_ids
    Person
      .joins(:taggings)
      .where.not('taggings.taggable_id': dst_tagged_person_ids)
      .where('taggings.tag_id': @src_tag_ids)
      .pluck(:id)
  end

  def dst_tagged_person_ids
    Person
      .joins(:taggings)
      .where('taggings.tag_id': @dst_tag_id)
      .pluck(:id)
  end

  def collect_taggings
    taggable_person_ids.collect do |i|
      { taggable_id: i,
        taggable_type: Person.name,
        tag_id: @dst_tag_id,
        created_at: Time.zone.now,
        context: :tags }
    end
  end

  def validation_tag_ids
    @validation_tag_ids ||= PersonTags::Validation.list.collect(&:id)
  end

end
