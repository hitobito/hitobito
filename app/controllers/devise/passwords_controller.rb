# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_dependency Devise::Engine.root.
                                  join('app', 'controllers', 'devise', 'passwords_controller').
                                  to_s

class Devise::PasswordsController < DeviseController

  def successfully_sent?(resource)
    if resource.login?
      super
    else
      flash[:alert] = I18n.translate('devise.failure.signin_not_allowed')
    end
  end

end
