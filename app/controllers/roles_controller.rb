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

  before_render_form :set_group_selection

  hide_action :index, :show

  def create
    assign_attributes
    new_person = entry.person.new_record?
    created = create_entry_and_person
    respond_with(entry, success: created, location: after_create_location(new_person))
  end

  def update
    @group = find_group
    type = changed_type
    if type
      change_type(type)
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
    @group = find_group
    @type = @group.class.find_role_type!(model_params[:type]) if model_params[:type].present?
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
      raise ActiveRecord::Rollback unless created
    end
    created
  end

  def changed_type
    type = nil
    if model_params
      model_params.delete(:person_id)
      type = model_params.delete(:type)
    end

    type if @group.id != entry.group_id || (type && type != entry.type)
  end

  def change_type(type)
    @type = @group.class.find_role_type!(type)
    new_role = @type.new
    new_role.attributes = model_params
    new_role.person_id = entry.person_id
    new_role.group_id = @group.id
    authorize!(:create, new_role)
    Role.transaction do
      new_role.save!
      entry.destroy
    end
    flash[:notice] = role_change_message(new_role)
    @role = new_role
  end

  def build_entry
    # delete unused attributes
    if model_params
      model_params.delete(:person)
    end

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
    type = model_params && model_params.delete(:type)
    if type.present?
      @type = @group.class.find_role_type!(type)
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
      role.person = Person.new unless role.person
    else
      role.person = Person.new(person_attrs)
    end
  end

  def find_group
    id = model_params && model_params.delete(:group_id)
    id ? Group.find(id) : parent
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label(role = entry)
    "#{models_label(false)} <i>#{h(role)}</i> für <i>#{h(role.person)}</i> in <i>#{h(role.group)}</i>".html_safe
  end

  def role_change_message(new_role)
    new_role_label = "<i>#{h(new_role)}</i>"
    new_role_label << " in <i>#{h(@group)}</i>" if @group.id != @role.group_id
    I18n.t('roles.role_changed', old_role: full_entry_label, new_role: new_role_label).html_safe
  end

  def after_create_location(new_person)
    return_path ||
      if new_person && entry.person && entry.person.persisted?
        group_person_path(entry.group_id, entry.person_id)
      else
        group_people_path(entry.group_id)
      end
  end

  def set_group_selection
    if can?(:create_in_subgroup, entry)
      @group_selection = @group.groups_in_same_layer.to_a
    end
  end

  def h(string)
    ERB::Util.h(string)
  end
end
