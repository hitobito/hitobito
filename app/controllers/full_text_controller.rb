# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FullTextController < ApplicationController
  MIN_TERM_LENGTH = 3

  skip_authorization_check

  helper_method :active_tab_class, :query?

  respond_to :html

  SEARCHABLE_MODELS = [
    [:people, SearchStrategies::PersonSearch],
    [:groups, SearchStrategies::GroupSearch],
    [:events, SearchStrategies::EventSearch],
    [:invoices, SearchStrategies::InvoiceSearch, -> { current_ability.can?(:index, Invoice) }]
  ].freeze

  def index
    respond_to do |format|
      format.html { query_results }
      format.json { render json: query_json_results }
    end
  end

  private

  def query_results
    each_search_result do |key, result|
      decorator = "decorate_#{key}"
      list = respond_to?(decorator, true) ? send(decorator, result) : result
      instance_variable_set(:"@#{key}", list)
    end

    if only_result.present?
      redirect_to polymorphic_path(only_result)
    else
      @active_tab = active_tab
    end
  end

  def query_json_results
    each_search_result do |key, result|
      instance_variable_set(:"@#{key}", quicksearch_result(key, result))
    end

    results_with_separator || []
  end

  def quicksearch_result(key, result)
    result.collect do |i|
      "#{key.to_s.singularize.titleize}Decorator".constantize.new(i).as_quicksearch
    end
  end

  def each_search_result(limit: nil)
    return unless query?

    SEARCHABLE_MODELS.each do |key, search_class, condition|
      if !condition || instance_exec(&condition)
        yield key, search_result(search_class)
      end
    end
  end

  def search_result(search_class)
    search_class.new(current_user, query_param, params[:page]).search
  end

  def results_with_separator
    all_results.inject do |memo, set|
      memo + [{label: "—" * 20}] + set
    end
  end

  # return the only result if the search term only matches a single result for all searchable models
  def only_result
    all = all_results.flatten
    all.first if all.size == 1
  end

  def all_results
    [@people, @groups, @events, @invoices].compact_blank
  end

  def active_tab
    return :people if @people.present?
    return :groups if @groups.present?
    return :events if @events.present?
    return :invoices if @invoices.present?

    :people
  end

  def active_tab_class(tab)
    "active" if @active_tab == tab
  end

  def decorate_events(events)
    events.map do |event|
      EventDecorator.new(event)
    end
  end

  def decorate_invoices(invoices)
    invoices.map do |invoice|
      InvoiceDecorator.new(invoice)
    end
  end

  def query?
    query_param.size >= MIN_TERM_LENGTH
  end

  def query_param
    params[:q].to_s.strip
  end
end
