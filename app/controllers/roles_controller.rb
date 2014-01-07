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
    assign_attributes

    new_person = entry.person && entry.person.new_record?
    created = create_entry_and_person
    respond_with(entry, success: created, location: after_create_location(new_person))
  end

  def update
    type = nil
    if model_params
      model_params.delete(:person_id)
      model_params.delete(:group_id)
      type = model_params.delete(:type)
    end
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

  def details
    @group = parent
    @type = parent.class.find_role_type!(model_params[:type]) if model_params[:type].present?
  end

  private

  def create_entry_and_person
    created = false
    Role.transaction do
      created = with_callbacks(:create, :save) do
        entry.valid? && entry.person.save && entry.save
      end
      raise ActiveRecord::Rollback unless created
    end
    created
  end

  def handle_type_change(type)
    role = parent.class.find_role_type!(type).new
    role.attributes = model_params
    role.person_id = entry.person_id
    role.group_id = entry.group_id
    role.save!
    entry.destroy
    flash[:notice] = I18n.t('roles.role_changed', old_role: full_entry_label, new_role: role).html_safe
    set_model_ivar(role)
  end

  def build_entry
    # delete unused attributes
    if model_params
      model_params.delete(:group_id)
      model_params.delete(:person)
    end

    role = build_role
    build_person(role)
    role.group_id = parent.id
    role
  end

  def find_entry
    super.tap { |role| @type = role.class }
  end

  def build_role
    type = model_params && model_params.delete(:type)
    if type.present?
      @type = parent.class.find_role_type!(type)
      @type.new
    else
      Role.new
    end
  end

  def build_person(role)
    person_attrs = (model_params && model_params.delete(:new_person)) || {}
    person_id = model_params && model_params.delete(:person_id)
    if person_id.present?
      role.person_id = person_id
    else
      role.person = Person.new(person_attrs)
    end
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label(role = entry)
    "#{models_label(false)} #{RoleDecorator.decorate(role).flash_info}".html_safe
  end

  def after_create_location(new_person)
    return_path ||
      if new_person && entry.person && entry.person.persisted?
        group_person_path(entry.group_id, entry.person_id)
      else
        group_people_path(entry.group_id)
      end
  end
end
