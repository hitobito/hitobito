#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassGrantsController < CrudController
  self.nesting = Group, PassDefinition

  self.permitted_attrs = [] # role_types handled in assign_attributes

  skip_authorize_resource
  before_action :authorize_class

  prepend_before_action :parent

  before_render_form :load_role_types
  before_render_form :replace_validation_errors

  def self.model_class
    PassGrant
  end

  # GET query — queries available groups via ajax
  def query
    groups = []
    if params.key?(:q) && params[:q].size >= 3
      groups = decorate(groups_query)
    end

    render json: groups.collect(&:as_typeahead)
  end

  # GET roles — renders role type checkboxes for a selected group via ajax
  def roles
    load_role_types
  end

  def create
    super(location: group_pass_definition_path(group, pass_definition))
  end

  def edit
    @selected_group ||= Group.find(entry.grantor_id)
    load_role_types
  end

  def update
    super do |format|
      format.html do
        redirect_to group_pass_definition_path(group, pass_definition)
      end
    end
  end

  def destroy
    super(location: group_pass_definition_path(group, pass_definition))
  end

  private

  def groups_query
    possible_groups
      .where(search_condition("groups.name"))
      .includes(:parent).references(:parent)
      .reorder("#{Group.quoted_table_name}.lft")
      .limit(10)
  end

  def possible_groups
    group.self_and_descendants.without_deleted.without_archived
  end

  def assign_attributes
    super
    if model_params
      entry.grantor = Group.find(model_params[:grantor_id]) if model_params[:grantor_id].present?
      entry.role_types = model_params[:role_types]
    end
  end

  def build_entry
    pass_definition.pass_grants.build
  end

  def load_role_types
    @role_types = Role::TypeList.new(grantor.class) if grantor
  end

  def grantor
    @selected_group ||= Group.where(id: grantor_id).first
  end

  def grantor_id
    model_params&.dig(:grantor_id) || entry.grantor_id
  end

  def replace_validation_errors
    if entry.errors[:grantor_type].present?
      entry.errors.delete(:grantor)
      entry.errors.delete(:grantor_id)
      entry.errors.delete(:grantor_type)
      entry.errors.add(:base, I18n.t("pass_grants.errors.group_required"))
    end
  end

  def authorize_class
    authorize!(:edit, pass_definition)
  end

  def pass_definition
    parent
  end

  def group
    parents.first
  end
end
