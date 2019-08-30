#  Copyright (c) 2019, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Tag
  class List

    attr_reader :ability, :params
    delegate :authorize!, :can?, to: :ability

    def initialize(ability, params)
      @ability = ability
      @params = params
    end

    def existing_tags_with_count
      manageable_people.flat_map do |person|
        person.tags
      end.group_by { |tag| tag }.map { |tag, occurrences| [tag, occurrences.count] }
    end

    def build_new_tags(logger)
      logger.debug(manageable_people.inspect)
      all_combinations = manageable_people.product(tags)
      logger.debug(all_combinations.inspect)
      hashes = all_combinations.map {|elem| {elem[0] => elem[1]}}
      logger.debug(hashes.inspect)
      hashes.select do |hash|
        person, tag = hash
        not person.tag_list.include? tag
      end
    end

    def tag_ids
      tags.keys
    end

    def manageable_people_ids
      manageable_people.map(&:id)
    end

    private

    def access_denied_flash(person)
      I18n.t('tag_lists.access_denied', person: person.full_name)
    end

    #def permitted_params(role_type = Role)
    #  permitted_attrs = RoleListsController.permitted_attrs
    #  model_params.permit(role_type.used_attributes + permitted_attrs)
    #end

    #def group
    #  @group ||= Group.find(params[:group_id])
    #end

    #def new_group
    #  @new_group ||= Group.find(model_params[:group_id])
    #end

    def tags
      model_params || {}
    end

    def manageable_people
      people.select { |person| can?(:manage_tags, person) }
    end

    def people
      @people ||= Person.includes(:tags).where(id: people_ids).uniq
    end

    def people_ids
      params[:ids].to_s.split(',')
    end

    def model_params
      params[:tags]
    end
  end
end
