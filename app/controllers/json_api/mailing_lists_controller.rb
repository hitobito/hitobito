# frozen_string_literal: true

#  Copyright (c) 2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::MailingListsController < JsonApiController
  def index
    authorize!(:index, MailingList)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  private

  def entry
    @entry ||= MailingList.joins(:group).find(params[:id])
  end
end
