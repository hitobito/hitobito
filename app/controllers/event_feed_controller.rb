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

  helper_method :feed_url

  def feed
    return render nothing: true, status: :unauthorized unless token_valid?
    send_data ::Export::Ics::Events.new.generate(person.events), type: :ics, disposition: :inline
  end

  def index
  end

  def reset
    current_user.update_attribute(:event_feed_token, SecureRandom.urlsafe_base64)
    redirect_to action: :index
  end

  private

  def feed_url
    url_for action: :feed,
            person_id: current_user.id,
            token: current_user.event_feed_token,
            format: :ics, only_path: false
  end

  def token_valid?
    params.require(:token)
    expected_token.present? && (params[:token] == expected_token)
  end

  def expected_token
    @expected_token ||= person.event_feed_token
  end

  def person
    params.require(:person_id)
    @person ||= Person.find(params[:person_id])
  end

end
