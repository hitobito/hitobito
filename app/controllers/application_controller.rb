# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationController < ActionController::Base

  include Concerns::DecoratesBeforeRendering
  include Userstamp
  include Translatable
  include Concerns::Stampable
  include Concerns::Localizable
  include Concerns::Authenticatable
  include ERB::Util

  alias_method :decorate, :__decorator_for__

  protect_from_forgery with: :exception
  helper_method :person_home_path

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to root_path, alert: I18n.t('devise.failure.not_permitted_to_view_page')
  end if Rails.env.production?


  private

  def person_home_path(person)
    group_person_path(person.default_group_id, person)
  end

end
