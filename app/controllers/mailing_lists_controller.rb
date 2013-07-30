# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListsController < CrudController


  self.nesting = Group

  decorates :group, :mailing_list

  prepend_before_filter :parent


  def show
    @mailing_list = entry
  end

  private

  def list_entries
    super.order(:name)
  end


  alias_method :group, :parent

end
