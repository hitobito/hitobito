# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::MessagesController < ListController
  include YearBasedPaging

  private

  def list_entries
    Message.list.includes(:message_recipients)
      .where(message_recipients: {person_id: person.id})
      .page(params[:page]).per(50).where(created_at: year_filter)
  end

  def person
    @person ||= fetch_person
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:index_messages, person)
  end
end
