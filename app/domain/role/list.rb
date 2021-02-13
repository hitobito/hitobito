#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Role
  class List

    attr_reader :ability, :params
    delegate :authorize!, :can?, to: :ability

    def initialize(ability, params)
      @ability = ability
      @params = params
    end

    def build_new_roles_hash
      people.map do |person|
        role = build_role(person.id)
        authorize!(:create, role, message: access_denied_flash(person))
        role.attributes
      end
    end

    def collect_available_role_types
      roles.each_with_object({}) do |role, hash|
        next unless can?(:destroy, role)
        key = role.group.name
        hash[key] = {} if hash[key].blank?

        type = role.type
        count = hash[key][type].blank? ? 1 : hash[key][type] + 1
        hash[key][type] = count
      end
    end

    def deletable_role_ids
      roles.where(type: role_types.keys).map do |r|
        authorize!(:destroy, r, message: access_denied_flash(r.person)).id
      end
    end

    private

    def build_role(person_id)
      role = build_role_type
      role.attributes = permitted_params(@type)
      role.person_id = person_id
      role
    end

    def build_role_type
      @type = new_group.class.find_role_type!(model_params[:type])
      @type.new
    end

    def access_denied_flash(person)
      I18n.t("role_lists.access_denied", person: person.full_name)
    end

    def permitted_params(role_type = Role)
      permitted_attrs = RoleListsController.permitted_attrs
      model_params.permit(role_type.used_attributes + permitted_attrs)
    end

    def group
      @group ||= Group.find(params[:group_id])
    end

    def new_group
      @new_group ||= Group.find(model_params[:group_id])
    end

    def roles
      group_ids = params[:range] == ("layer" || "deep") ? layer_group_ids : group
      @roles ||= Role.where(person_id: people_ids, group_id: group_ids)
    end

    def role_types
      model_params && model_params[:types] ? model_params[:types] : {}
    end

    def people
      @people ||= Person.where(id: people_ids).distinct
    end

    def layer_group_ids
      group.groups_in_same_layer.pluck(:id)
    end

    def people_ids
      params[:ids].to_s.split(",")
    end

    def model_params
      params[:role]
    end

  end
end
