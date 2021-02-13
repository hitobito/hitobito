# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddressesController < ApplicationController
  skip_authorization_check

  def query
    render json: Address::FullTextSearch.new(query_param, search_strategy).typeahead_results
  end

  def query_param
    params[:q]
  end

  private

  def search_strategy
    @search_strategy ||= search_strategy_class.new(current_user, query_param, params[:page])
  end

  def search_strategy_class
    if sphinx?
      SearchStrategies::Sphinx
    else
      SearchStrategies::Sql
    end
  end

  def sphinx?
    Hitobito::Application.sphinx_present?
  end
end
