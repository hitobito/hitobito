# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_dependency Devise::Engine.root.
                                  join('app', 'controllers', 'devise', 'registrations_controller').
                                  to_s

class Devise::RegistrationsController < DeviseController

  before_action :has_old_password, only: [:edit, :update]
  before_action :reject_non_password_params, only: [:update]

  private

  # this controller writes all person attributes, we use it to change the password
  # therefore we reject all but the password param
  def reject_non_password_params
    params[:person].select! { |key| key =~ /password/ }
  end

  # rubocop:disable PredicateName

  def has_old_password
    @old_password = resource.encrypted_password?
  end
end
