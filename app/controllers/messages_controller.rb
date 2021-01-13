# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MessagesController < CrudController
  include YearBasedPaging
  self.permitted_attrs = [:type, :subject, :body]

  self.nesting = [Group, MailingList]
  self.remember_params += [:year]

  before_render_form :set_recipient_count

  private

  def list_entries
    super.list.page(params[:page]).per(50).where(created_at: year_filter)
  end

  def build_entry
    raise_type_error unless well_known?(type)
    type.constantize.new(mailing_list: parent, sender: current_user)
  end

  def type
    model_params && model_params[:type].presence
  end

  def well_known?(type)
    type.safe_constantize&.new&.is_a?(Message)
  end

  def raise_type_error
    raise ActiveRecord::RecordNotFound, "No message type '#{type}' found"
  end

  def authorize_class
    authorize!(:update, parent)
  end

  def set_recipient_count
    @recipient_count = parent.people.size
  end

end
