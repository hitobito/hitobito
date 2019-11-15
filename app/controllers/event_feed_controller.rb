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

  def feed
    return render nothing: true, status: :unauthorized unless token_valid?
    events = current_user.decorate.upcoming_events
    send_data ::Export::Ics::Events.new.generate(events), type: :ics, disposition: :inline
  end

  def index
  end

  def reset
    current_user.update_attribute(:event_feed_token, SecureRandom.urlsafe_base64)
    redirect_to action: :index
  end

  private

  def token_valid?
    params.require(:token)
    params.require(:person_id)
    expected_token.present? && (params[:token] == expected_token)
  end

  def expected_token
    @expected_token ||= Person.find(params[:person_id]).event_feed_token
  end

end
