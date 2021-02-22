#  Copyright (c) 2015-2017, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::AttachmentsController < CrudController
  skip_authorize_resource
  before_action :authorize_action

  self.nesting = Group, Event

  self.permitted_attrs = [:file]

  respond_to :js

  def self.model_class
    Event::Attachment
  end

  private

  alias event parent

  def index_path
    group_event_path(*parents)
  end

  def authorize_action
    authorize!(:update, event)
  end
end
