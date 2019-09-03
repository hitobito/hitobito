#  Copyright (c) 2019, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Tag
  class List

    attr_reader :ability, :params
    delegate :can?, to: :ability

    def initialize(ability, params)
      @ability = ability
      @params = params
    end

    def existing_tags_with_count
      manageable_people.flat_map do |person|
        person.tags
      end.group_by { |tag| tag }.map { |tag, occurrences| [tag, occurrences.count] }
    end

    def build_new_tags
      new_tags = manageable_people.map do |person|
        [person, tags - person.tags]
      end
      { hash: new_tags.to_h, count: new_tags.sum { |e| e[1].count } }
    end

    def tag_ids
      tags.map(&:id)
    end

    def manageable_people_ids
      manageable_people.map(&:id)
    end

    private

    def tags
      @tags ||= ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(model_params)
    end

    def manageable_people
      @manageable_people ||= people.select { |person| can?(:manage_tags, person) }
    end

    def people
      @people ||= Person.includes(:tags).where(id: people_ids).uniq
    end

    def people_ids
      params[:ids].to_s.split(',')
    end

    def model_params
      return [] if params[:tags].nil?
      return params[:tags].keys if params[:tags].is_a?(Hash)
      params[:tags].split(',').each(&:strip)
    end
  end
end
