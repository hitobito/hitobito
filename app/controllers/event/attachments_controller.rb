#  Copyright (c) 2015-2017, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::AttachmentsController < CrudController
  skip_authorize_resource
  before_action :authorize_action

  self.nesting = Group, Event

  self.permitted_attrs = [:visibility]

  respond_to :js

  def self.model_class
    Event::Attachment
  end

  def create
    @attachments = model_params[:files].map do |file|
      model_scope.create(file: file)
    end

    render "create"
  end

  private

  alias_method :event, :parent

  def set_success_notice
    # Skip this, this controller only serves JS
  end

  def index_path
    group_event_path(*parents)
  end

  def authorize_action
    authorize!(:manage_attachments, event)
  end
end
