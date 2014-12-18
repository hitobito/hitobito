# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListsController < CrudController

  self.nesting = Group

  self.permitted_attrs = [:name, :description, :publisher, :mail_name,
                          :additional_sender, :subscribable, :subscribers_may_post]

  decorates :group, :mailing_list

  prepend_before_action :parent


  def show
    @mailing_list = entry
    respond_with(@mailing_list)
  end

  private

  def list_entries
    super.order(:name)
  end

  def authorize_class
    authorize!(:index_mailing_lists, group)
  end

  alias_method :group, :parent

end
