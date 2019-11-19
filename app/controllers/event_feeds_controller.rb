# encoding: utf-8

#  Copyright (c) 2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventFeedsController < ApplicationController

  def show
    respond_to do |format|
      format.html { authorize!(:show, current_user) }
      format.ics do
        person = Person.find_by(event_feed_token: params[:token]) if params[:token].present?
        return render nothing: true, status: :not_found unless person
        send_data ::Export::Ics::Events.new.generate(person.events), type: :ics, disposition: :inline
      end
    end
  end

  def update
    authorize!(:update, current_user)
    key = current_user.event_feed_token ? :reset : :create
    current_user.update_attribute(:event_feed_token, generate_token)
    redirect_to :event_feed, notice: t("event_feeds.update.flash.#{key}")
  end

  private

  def generate_token
    loop do
      token = SecureRandom.urlsafe_base64
      break token unless Person.where(event_feed_token: token).exists?
    end
  end

  def devise_controller?
    request.format.ics? # hence, no login required
  end

end
