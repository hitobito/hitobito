# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddressesController < ApplicationController
  skip_before_action :authenticate_person!
  skip_authorization_check

  def query
    raise ActionController::BadRequest if query_param.nil?

    render json: Address::FullTextSearch.new(query_param).typeahead_results
  end

  def query_param
    params[:q]
  end
end
