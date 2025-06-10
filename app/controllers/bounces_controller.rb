# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class BouncesController < ListController
  self.nesting = [Group, MailingList]

  helper_method :group, :mailing_list

  prepend_before_action :group
  prepend_before_action :mailing_list

  private

  def group
    @group ||= Group.find(params[:group_id])
  end

  def mailing_list
    return nil if params[:mailing_list_id].blank?

    @mailing_list ||= MailingList.find(params[:mailing_list_id])
  end

  def model_scope
    model_class.of_mailing_list(mailing_list&.id)
  end
end
