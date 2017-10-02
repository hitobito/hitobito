# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FullTextController < ApplicationController

  skip_authorization_check

  helper_method :entries

  respond_to :html

  def index
    @people = if params[:q].to_s.size >= 2
                PaginatingDecorator.decorate(search_strategy.list_people)
              else
                Kaminari.paginate_array([]).page(1)
              end
    respond_with(@people)
  end

  def query
    people = search_strategy.query_people.collect { |i| PersonDecorator.new(i).as_quicksearch }
    groups = search_strategy.query_groups.collect { |i| GroupDecorator.new(i).as_quicksearch }
    events = search_strategy.query_events.collect { |i| EventDecorator.new(i).as_quicksearch }

    render json: results_with_separator(people, groups, events) || []
  end

  private

  def results_with_separator(*sets)
    sets.select(&:present?).inject do |memo, set|
      memo + [{ label: '—' * 20 }] + set
    end
  end

  def search_strategy
    @search_strategy ||= search_strategy_class.new(current_user, params[:q], params[:page])
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

  def entries
    @people
  end
end
