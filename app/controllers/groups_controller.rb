# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupsController < CrudController

  include AsyncDownload

  # Respective group attrs are added in corresponding instance method.
  self.permitted_attrs = Contactable::ACCESSIBLE_ATTRS.dup + [
    :logo,
    :letter_logo,
    :nextcloud_url,
    :privacy_policy,
    :privacy_policy_title,
    :remove_logo,
    :remove_letter_logo,
    :remove_privacy_policy,
    :self_registration_notification_email,
    :self_registration_role_type,
    :self_registration_require_adult_consent,
    :main_self_registration_group,
    :custom_self_registration_title
  ]

  # required to allow api calls
  protect_from_forgery with: :null_session, only: [:index, :show]

  decorates :group, :groups, :contact

  before_render_show :active_sub_groups, if: -> { html_request? }
  before_render_form :load_contacts
  after_save :update_main_self_registration_group

  def index
    flash.keep if html_request?
    redirect_to group_path(Group.root.id, format: request.format.to_sym)
  end

  def show
    super do |format|
      format.json do
        render json: GroupSerializer.new(entry.decorate, controller: self)
      end
    end
  end

  def update
    new_attr_value = permitted_params[:main_self_registration_group].present?
    if entry.main_self_registration_group != new_attr_value
      # only people with `set_main_self_registration_group` ability may update this attribute
      authorize!(:set_main_self_registration_group, entry)
    end

    super
  end

  def destroy
    super(location: entry.parent)
  end

  def deleted_subgroups
    load_sub_groups(entry.children.only_deleted)
  end

  def reactivate
    entry.restore!

    flash[:notice] = translate(:reactivated, group: entry)
    redirect_to entry
  end

  def export_subgroups
    with_async_download_cookie(:csv, :subgroups_export, redirection_target: entry) do |filename|
      Export::SubgroupsExportJob.new(current_person.id, entry.id, filename: filename).enqueue!
    end
  end

  def person_notes; end

  private

  def update_main_self_registration_group
    return unless FeatureGate.enabled?('groups.self_registration') &&
      entry.saved_change_to_main_self_registration_group? &&
      entry.main_self_registration_group

    Group.where.not(id: entry.id).update_all(main_self_registration_group: false)
  end

  def build_entry
    type = model_params && model_params[:type]
    group = Group.find_group_type!(type).new
    group.parent_id = model_params[:parent_id]
    group
  end

  def permitted_attrs
    attrs = entry.class.used_attributes.dup
    attrs += self.class.permitted_attrs
    attrs += entry.class.mounted_attr_names
    if entry.class.superior_attributes.present? && !can?(:modify_superior, entry)
      attrs -= entry.class.superior_attributes
    end
    if entry.static_name
      attrs -= [:name, :short_name]
    end
    attrs
  end

  def permitted_params
    p = model_params.dup
    p.delete(:type)
    p.delete(:parent_id)
    p.permit(permitted_attrs)
  end

  def load_contacts
    @contacts = entry.people.members.distinct.only_public_data.order_by_name
  end

  def active_sub_groups
    load_sub_groups(entry.children.without_deleted)
  end

  def load_sub_groups(scope)
    @sub_groups = Hash.new { |h, k| h[k] = [] }
    scope.order(:lft).each do |group|
      if can?(:show, group)
        label = group.layer ? group.class.label_plural : sub_groups_label
        @sub_groups[label] << group
      end
    end
    # move entry with non-layer groups to the end
    children = @sub_groups.delete(sub_groups_label)
    @sub_groups[sub_groups_label] = children if children
  end

  def sub_groups_label
    @sub_groups_label ||= translate(:subgroups)
  end

end
