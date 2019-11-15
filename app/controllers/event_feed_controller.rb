# encoding: utf-8

#  Copyright (c) 2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventFeedController < ApplicationController

  authorize_resource :person, except: :feed
  skip_authorization_check only: :feed
  skip_before_action :authenticate_person!, only: :feed
  respond_to :ics, only: :feed

  class_attribute :permitted_attrs
  self.permitted_attrs = [:token]

  def feed
    # TODO check authorization using token
    events = person.decorate.upcoming_events
    send_data ::Export::Ics::Events.new.generate(events), type: :ics, disposition: :inline
  end

  def index
    person
  end

  private

  def permitted_params
    params.require(model_identifier).permit(permitted_attrs)
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

end
