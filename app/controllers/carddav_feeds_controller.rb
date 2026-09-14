# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class CarddavFeedsController < ApplicationController
  def show
    authorize!(:show, current_user)
  end

  def update
    authorize!(:update, current_user)
    key = current_user.carddav_token ? :reset : :create
    current_user.update_attribute(:carddav_token, SecureRandom.urlsafe_base64)
    redirect_to :carddav_feed, notice: t("carddav_feeds.update.flash.#{key}")
  end
end
