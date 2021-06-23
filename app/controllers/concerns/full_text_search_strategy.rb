# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

# currently used by
# - AddressesController
# - FullTextController
module FullTextSearchStrategy
  private

  def query_param
    params[:q]
  end

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
