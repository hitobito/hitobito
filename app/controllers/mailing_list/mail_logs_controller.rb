# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class MailingList::MailLogsController < CrudController

  include YearBasedPaging

  self.nesting = Group, MailingList

  private

  def list_entries
    mailing_list.mail_logs.list.in_year(year)
  end

  def mailing_list
    MailingList.find(mailing_list_id)
  end

  def mailing_list_id
    params[:mailing_list_id]
  end

  def authorize_class
    authorize!(:update, mailing_list)
  end

end
