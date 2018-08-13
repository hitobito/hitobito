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
                          :mailchimp_api_key, :mailchimp_list_id,
                          :syncing_mailchimp, :last_synced_mailchimp_at, preferred_labels: []]

  decorates :group, :mailing_list

  before_destroy :destroy_in_mailchimp

  prepend_before_action :parent
  before_render_form :load_labels

  respond_to :js

  def edit
    assign_attributes if request.format.js?
    super
  end

  private

  def destroy_in_mailchimp
    if connected_to_mailchimp? and entry.people.any?
      MailchimpDestructionJob.new(entry.mailchimp_list_id, entry.mailchimp_api_key, entry.people).enqueue!
    end
  end

  def connected_to_mailchimp?
    entry.mailchimp_api_key.present? and entry.mailchimp_list_id.present?
  end

  def list_entries
    super.order(:name)
  end

  def authorize_class
    authorize!(:index_mailing_lists, group)
  end

  def load_labels
    @labels = AdditionalEmail.uniq.pluck(:label)
    @preferred_labels = entry.preferred_labels.sort
  end

  alias_method :group, :parent

end
