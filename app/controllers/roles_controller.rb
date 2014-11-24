# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RolesController < CrudController
  respond_to :js

  self.nesting = Group

  decorates :role, :group

  # load group before authorization
  prepend_before_action :parent

  before_render_form :set_group_selection

  hide_action :index, :show

  def create
    assign_attributes
    new_person = entry.person.new_record?
    created = create_entry_and_person
    respond_with(entry, success: created, location: after_create_location(new_person))
  end

  def update
    if change_type?
      change_type
    else
      super(location: after_update_location)
    end
  end

  def destroy
    super do |format|
      location = can?(:show, entry.person) ? person_path(entry.person_id) : group_path(parent)
      format.html { redirect_to(location) }
    end
  end

  def details
    @group = find_group
    if model_params && model_params[:type].present?
      @type = @group.class.find_role_type!(model_params[:type])
    end
  end

  def role_types
    @group = Group.find(params[:role][:group_id])
  end

  private

  def create_entry_and_person
    created = false
    Role.transaction do
      created = with_callbacks(:create, :save) do
        entry.person.save && entry.save
      end
      fail ActiveRecord::Rollback unless created
    end
    created
  end

  def change_type?
    extract_model_attr(:person_id)
    type = model_params && model_params[:type]

    @group.id != entry.group_id || (type && type != entry.type)
  end

  def change_type
    if create_new_role_and_destroy_old_role
      @role, @old_role = @new_role, @role
      respond_to do |format|
        format.html { redirect_to(after_update_location, notice: role_change_message) }
        format.js
      end
    else
      copy_errors(@new_role)
      render :edit
    end
  end

  def create_new_role_and_destroy_old_role
    @new_role = build_new_type
    authorize!(:create, @new_role)

    Role.transaction do
      @new_role.save && entry.destroy
    end
  end

  def build_new_type
    new_role = build_role
    new_role.attributes = permitted_params(@type)
    new_role.person_id = entry.person_id
    new_role.group_id = @group.id
    new_role
  end

  def copy_errors(new_role)
    entry.attributes = new_role.attributes.except('id')
    new_role.errors.each do |key, value|
      entry.errors.add(key, value)
    end
  end

  def build_entry
    # delete unused attributes
    extract_model_attr(:person)

    role = build_role
    role.group_id = @group.id
    build_person(role)

    role
  end

  def find_entry
    super.tap { |role| @type = role.class }
  end

  def build_role
    @group = find_group
    type = extract_model_attr(:type)
    if type.present?
      @type = @group.class.find_role_type!(type)
      @type.new
    else
      Role.new
    end
  end

  def build_person(role)
    person_attrs = extract_model_attr(:new_person) || {}
    person_id = extract_model_attr(:person_id)
    if person_id.present?
      role.person_id = person_id
      role.person = Person.new unless role.person
    else
      attrs = ActionController::Parameters.new(person_attrs).
               permit(*PeopleController.permitted_attrs)
      role.person = Person.new(attrs)
    end
  end

  def permitted_params(role_type = entry.class)
    model_params.permit(role_type.used_attributes)
  end

  def find_group
    id = extract_model_attr(:group_id)
    id ? Group.find(id) : parent
  end

  def extract_model_attr(attr)
    model_params && model_params.delete(attr)
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label(role = entry)
    translate(:full_entry_label, model_label: models_label(false),
                                 role: h(role),
                                 person: h(role.person),
                                 group: h(role.group)).html_safe
  end

  def role_change_message
    key = @group.id == @old_role.group.id ? :role_changed : :role_changed_to_group
    translate(key, full_entry_label: full_entry_label(@old_role), new_role: h(@role),
                   new_group: h(@group))
  end

  def after_create_location(new_person)
    return_path ||
      if new_person && entry.person && entry.person.persisted?
        group_person_path(entry.group_id, entry.person_id)
      else
        group_people_path(entry.group_id)
      end
  end

  def after_update_location
    group_person_path(entry.group_id, entry.person_id)
  end

  def set_group_selection
    if can?(:create_in_subgroup, entry)
      @group_selection = @group.groups_in_same_layer.to_a
    end
  end
end
