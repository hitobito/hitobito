# encoding: utf-8

#  Copyright (c) 2012-2014, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Devise::TokensController < DeviseController

  skip_before_action :authenticate_person!
  prepend_before_action :require_no_authentication
  prepend_before_action :allow_params_authentication!
  prepend_before_action :skip_trackable

  # json only controller
  respond_to :html, only: []
  respond_to :json

  # POST /resource/token
  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in resource, store: false
    resource.generate_authentication_token!
    render json: UserSerializer.new(resource, controller: self)
  end

  # DELETE /resource/token
  def destroy
    self.resource = warden.authenticate!(auth_options)
    sign_in resource, store: false
    resource.update_column(:authentication_token, nil)
    render json: UserSerializer.new(resource, controller: self)
  end

  private

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end

  def skip_trackable
    request.env['devise.skip_trackable'] = true
  end
end
