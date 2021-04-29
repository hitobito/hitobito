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
                          :mailchimp_include_additional_emails, :mailchimp_sync_first_name,
                          :mailchimp_sync_last_name, :mailchimp_sync_nickname,
                          :mailchimp_sync_gender, preferred_labels: []]

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

  def list_entries
    scope = super.list
    can?(:update, parent) ? scope : scope.subscribable
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
