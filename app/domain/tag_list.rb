#  Copyright (c) 2019, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class TagList

  attr_reader :ability, :params
  delegate :authorize!, :can?, to: :ability

  def initialize(ability, params)
    @ability = ability
    @params = params
  end

  #def build_new_tags_hash
  #  people.map do |person|
  #    role = build_role(person.id)
  #    authorize!(:create, role, message: access_denied_flash(person))
  #    role.attributes
  #  end
  #end

  def existing_tags_with_count
    manageable_people.flat_map do |person|
      person.tags
    end.group_by { |tag| tag }.map { |tag, occurrences| [tag, occurrences.count] }
  end

  def tag_ids
    (model_params || {}).keys
  end

  def manageable_people_ids
    manageable_people.map(&:id)
  end

  private

  #def build_role(person_id)
  #  role = build_role_type
  #  role.attributes = permitted_params(@type)
  #  role.person_id = person_id
  #  role
  #end

  #def build_role_type
  #  @type = new_group.class.find_role_type!(model_params[:type])
  #  @type.new
  #end

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
    params[:tag]
  end

end
