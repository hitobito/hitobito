# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Handles a top-level person route (/person/:id)
class Person::TopController < ApplicationController

  before_action :authorize_action

  def show
    redirect_to_home
  end

  private

  def entry
    @person ||= Person.find(params[:id])
  end

  def redirect_to_home
    flash.keep if html_request?
    redirect_to person_home_path(entry, format: request.format.to_sym)
  end

  def authorize_action
    authorize!(:show, entry)
  end

end
