# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RolesController < CrudController

  self.nesting = Group

  decorates :role, :group

  # load group before authorization
  prepend_before_filter :parent

  hide_action :index, :show

  def create
    super(location: return_path || group_people_path(entry.group_id))
  end

  def update
    type = model_params && model_params.delete(:type)
    if type && type != entry.type
      handle_type_change(type)
      redirect_to(group_person_path(entry.group_id, entry.person_id))
    else
      super(location: group_person_path(entry.group_id, entry.person_id))
    end
  end

  def destroy
    super do |format|
      location = can?(:show, entry.person) ? person_path(entry.person_id) : group_path(parent)
      format.html { redirect_to(location) }
    end
  end

  private

  def handle_type_change(type)
    role = parent.class.find_role_type!(type).new
    role.person_id = entry.person_id
    role.group_id = entry.group_id
    role.label = model_params[:label]
    role.save!
    entry.destroy
    flash[:notice] = I18n.t('roles.role_changed', old_role: full_entry_label, new_role: role).html_safe
    set_model_ivar(role)
  end

  def build_entry
    # delete unused attributes
    type = nil
    if model_params
      model_params.delete(:group_id)
      model_params.delete(:person)
      type = model_params.delete(:type)
    end

    role = parent.class.find_role_type!(type).new
    role.group_id = parent.id
    role.person_id = model_params.delete(:person_id)
    role
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label(role=entry)
    "#{models_label(false)} #{RoleDecorator.decorate(role).flash_info}".html_safe
  end
end
