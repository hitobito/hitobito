# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Used to generate static error pages with the application layout:
# RAILS_GROUPS=assets rails generate error_page {status}
#
# Can also be used for dynamic error pages if those static files do not exist.
class ErrorsController < ActionController::Base
  layout 'application'
  helper_method :current_person, :current_user, :origin_user

  protect_from_forgery with: :exception

  %w(404 500 503).each do |code|
    define_method("show#{code}") do
      formats = request.format.json? ? [:json] : [:html]
      render code, status: code, formats: formats
    end
  end

  private

  def current_user
    nil
  end

  def current_person
    nil
  end

  def origin_user
    false
  end

end
