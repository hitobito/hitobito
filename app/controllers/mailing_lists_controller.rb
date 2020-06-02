# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListsController < CrudController

  self.nesting = Group

  self.permitted_attrs = [:name, :description, :publisher, :mail_name,
                          :additional_sender, :subscribable, :subscribers_may_post,
                          :anyone_may_post, :main_email, :delivery_report,
                          :mailchimp_list_id, :mailchimp_api_key,
                          :mailchimp_include_additional_emails, preferred_labels: []]

  decorates :group, :mailing_list

  prepend_before_action :parent
  before_render_form :load_labels

  respond_to :js

  def edit
    assign_attributes if request.format.js?
    super
  end

  def show
    super do |format|
      format.json do
        render json: MailingListSerializer.new(entry.decorate, controller: self)
      end
    end
  end

  private

  def entries
    MailingList.where("subscribable = ? OR group_id IN (?)", true, accessible_mailing_lists_groups.flatten)
  end

  def accessible_mailing_lists_groups
    current_user.roles.map do |role|
      if role.permissions.include?(:group_full)
        [group.id]
      elsif role.permissions.include?(:group_and_below_full)
        group.self_and_descendants.pluck(:id)
      elsif role.permissions.include?(:layer_full)
        group.groups_in_same_layer.pluck(:id)
      elsif role.permissions.include?(:layer_and_below_full)
        group.groups_in_same_layer.map { |g| g.self_and_descendants.pluck(:id) }.flatten
      end
    end
  end

  def authorize_class
    authorize!(:index_mailing_lists, group)
  end

  def load_labels
    @labels = AdditionalEmail.distinct.pluck(:label)
    @preferred_labels = entry.preferred_labels.sort
  end

  alias group parent

end
