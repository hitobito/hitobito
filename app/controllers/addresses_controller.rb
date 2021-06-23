# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddressesController < ApplicationController
  include FullTextSearchStrategy

  skip_authorization_check

  def query
    render json: Address::FullTextSearch.new(query_param, search_strategy).typeahead_results
  end
end
